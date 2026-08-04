"""
build_email_campaigns_v2.py

Consolidates all campaign-list CSV exports into TWO files for ingestion by
MySQL via LOAD DATA LOCAL INFILE:

    campaigns.csv   campaign_id, campaign_name, campaign_date   (one row per file)
    sends.csv       contact_email, campaign_id, opens           (one row per send)

WHY TWO FILES (2026-08-04):
v1 wrote campaign_name inline on all ~453k send rows. At ~67 bytes per row for
a repeated string, campaign_name was ~30MB of a 47.5MB file -- roughly
two-thirds. LOAD DATA LOCAL streams the file from THIS machine to the server,
and the measured throughput was ~178 KB/s, so the load took ~4.5 minutes and
was entirely wire-bound: no index, schema, or regex change moved it.

Replacing the repeated name with a small int drops sends.csv to ~16MB (~1.5
min at the same throughput). The join back to campaign_name happens in SQL,
where the strings live once instead of 453k times. Do not "simplify" this back
to a single denormalized file.

Design notes carried over from v1 (all still load-bearing):
- campaign_name is the FULL filename stem (no .csv). The date prefix stays in
  the name on purpose: resends, "_1"/"_2" variants, and "Batch #N" files must
  remain distinct under the (contact_email, campaign_name) primary key.
- Files whose name contains "test" (case-insensitive) are excluded.
- The email column is found by EXACT (case-insensitive, whitespace-stripped)
  header match on "Email". Substring matching would wrongly hit "Email 2",
  "Reply email", or "Email Client", which all exist in these exports.
- "[Subscriber Deleted]" rows and blank emails are dropped. Duplicate emails
  within a file are deduped (case-insensitive) to avoid PK violations that
  would abort LOAD DATA mid-file.
- Delimiter is sniffed per file (comma vs tab) because some Excel exports of
  these lists have shipped as tab-delimited despite the .csv extension.
- Encoding: BOM-sniffed UTF-16 -> UTF-8(-sig) -> cp1252 fallback. Output is
  plain UTF-8, no BOM.
- Output line terminator is explicitly \r\n on BOTH files to match LINES
  TERMINATED BY '\r\n'. A terminator mismatch makes LOAD DATA ingest ZERO rows
  with no error -- the classic silent failure -- so this is pinned, not
  defaulted.
- Loud-failure policy: any file with a missing Email column, an unparseable
  date, or zero valid emails is reported and the script exits nonzero so the
  batch wrapper can flag it.

New in v2:
- campaign_id is assigned from the SORTED file list, so it is stable across
  runs given the same directory contents. It is NOT stable if files are added
  or removed between runs -- the ids are only meaningful within a single
  matched pair of output files. Always reload BOTH files together.
- ALL sends are written, including opens = 0. The opens > 0 filter belongs in
  SQL, not here: email_counts derives times_contacted_by_email from the full
  send universe, and filtering upstream would silently redefine that column
  from "times sent" to "times opened".
"""

import csv
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------- config ---
SRC_DIR = Path(r"C:\Users\benjamin.bowen\Repos\Sql-Queries\Code\Recurring\Campaign lists")
OUT_DIR = Path(r"C:\Users\benjamin.bowen\Repos\Sql-Queries\Code\Recurring")
OUT_CAMPAIGNS = OUT_DIR / "campaigns.csv"
OUT_SENDS = OUT_DIR / "sends.csv"

MAX_CAMPAIGN_NAME_LEN = 250                  # size the DDL column to match: VARCHAR(250)
MAX_EMAIL_LEN = 100                          # matches contact_email VARCHAR(100)
DELETED_SENTINEL = "[subscriber deleted]"    # compared lowercase
MAX_PROBLEMS_PER_FILE = 5                    # cap per-row problem spam

# Leading date: MM.DD.YYYY, tolerating a day range like "07.02-03.2026"
# (first day wins) and a trailing glued dash ("02.27.2026- ...").
DATE_RE = re.compile(r"^(\d{2})\.(\d{2})(?:-\d{2})?\.(\d{4})")

# --------------------------------------------------------------- helpers ---
def decode_bytes(raw: bytes) -> str:
	"""BOM-aware decode with cp1252 fallback (Excel's usual suspects)."""
	if raw[:2] in (b"\xff\xfe", b"\xfe\xff"):
		return raw.decode("utf-16")
	try:
		return raw.decode("utf-8-sig")
	except UnicodeDecodeError:
		return raw.decode("cp1252")


def sniff_delimiter(header_line: str) -> str:
	"""Tab-delimited 'csv' exports exist in the wild; pick the dominant one."""
	return "\t" if header_line.count("\t") > header_line.count(",") else ","


def parse_campaign_date(stem: str):
	m = DATE_RE.match(stem)
	if not m:
		return None
	mm, dd, yyyy = m.group(1), m.group(2), m.group(3)
	# Plausibility guard: reject impossible dates instead of letting a typo
	# like 13.40.2026 sail through into STR_TO_DATE-style silent nonsense.
	if not (1 <= int(mm) <= 12 and 1 <= int(dd) <= 31):
		return None
	return f"{yyyy}-{mm}-{dd}"


def find_col(headers, name):
	"""Exact match (case-insensitive, stripped). Returns (index, warning_or_None)."""
	matches = [i for i, h in enumerate(headers) if h.strip().lower() == name]
	if not matches:
		return None, f"no header exactly matching {name!r}"
	warnMsg = f"multiple {name!r} headers at columns {matches}; using first"
	warn = (warnMsg if len(matches) > 1 else None)
	return matches[0], warn


# ------------------------------------------------------------------ main ---
def main() -> int:
	# Can't find source directory
	if not SRC_DIR.is_dir():
		print(f"FATAL: source directory not found: {SRC_DIR}")
		return 1

	# Find files in source directory
	files = sorted(
		p for p in SRC_DIR.glob("*.csv")
		if "test" not in p.stem.lower()
	)
	if not files:
		print(f"FATAL: no non-test .csv files found in {SRC_DIR}")
		return 1

	# Variables for returning and reporting results
	campaign_rows = []     # (campaign_id, campaign_name, campaign_date)
	send_rows = []         # (contact_email, campaign_id, opens)
	problems = []          # (filename, description) -> Any problem produces nonzero exit
	total_deleted = 0
	total_blank = 0
	total_dupes = 0
	total_long = 0
	next_campaign_id = 1

	# Print beginning of report
	print(f"{'id':>4} {'file':<100} {'read':>6} {'kept':>6} {'del':>5} {'blank':>5} {'dupe':>5}")
	print("-" * 138)

	# Loop through all files discovered in the source directory
	for path in files:
		stem = path.stem

		# Skip names that are too long for the DDL column
		if len(stem) > MAX_CAMPAIGN_NAME_LEN:
			problems.append((stem, f"campaign name is {len(stem)} chars, exceeds {MAX_CAMPAIGN_NAME_LEN}"))
			continue

		# Parse leading date found in the campaign name
		campaign_date = parse_campaign_date(stem)
		if campaign_date is None:
			problems.append((stem, "could not parse leading MM.DD.YYYY date"))
			continue

		# Split the lines from the file text
		text = decode_bytes(path.read_bytes())
		lines = text.splitlines()

		# Log an empty file
		if not lines:
			problems.append((stem, "file is empty"))
			continue

		# Find the file delimiter, then read the lines, and find the headers
		delim = sniff_delimiter(lines[0])
		reader = csv.reader(lines, delimiter=delim)
		try:
			headers = next(reader)
		except StopIteration:
			problems.append((stem, "no header row"))
			continue

		# Search for the index of the email column, log any problems
		email_idx, warnEmails = find_col(headers, "email")
		if email_idx is None:
			problems.append((stem, warnEmails))
			continue
		if warnEmails:
			print(f"  WARN [{stem}]: {warnEmails}")

		# Search for the index of the Opens column: 
      # If an opens column is missing in a file, default to 0 opens down the rows, not skip the column entirely
		opens_idx, warnOpens = find_col(headers, "opens")
		if opens_idx is None:
			print(f"  WARN [{stem}]: no 'Opens' column; defaulting to 0")
		if warnOpens:
			print(f"  WARN [{stem}]: {warnOpens}")

		# This file gets an id whether or not it yields rows, 
      # so a zero-row campaign still shows up in campaigns.csv and can be spotted in SQL.
		campaign_id = next_campaign_id
		next_campaign_id += 1
		campaign_rows.append((campaign_id, stem, campaign_date))

		# Document read rows, kept rows, deleted rows, blank rows, duplicate rows
		seen = set()
		n_read = n_kept = n_deleted = n_blank = n_dupe = n_long = 0
		for row in reader:
			n_read += 1
			email = (row[email_idx].strip() if email_idx < len(row) else "")

         # Parse Opens
			strp_raw_opens = row[opens_idx].strip().replace(",", "")
			valid_open_idx = opens_idx is not None and opens_idx < len(row) 
			raw_opens = (strp_raw_opens if valid_open_idx else "")
			opens_default = "0" if opens_idx is None else r"\N"
			# \N is MySQL's NULL sentinel in LOAD DATA. 
			# Unparseable opens become NULL rather than 0 so the SQL side can tell "no data" from "no opens".
			opens = raw_opens if raw_opens.isdigit() else opens_default

         # Skip invalid emails and log which type of invalid
			key = email.lower()
			if not email:
				n_blank += 1
				continue
			if key == DELETED_SENTINEL:
				n_deleted += 1
				continue
			if key in seen:
				n_dupe += 1
				continue
			if len(email) > MAX_EMAIL_LEN:
				n_long += 1
				if n_long <= MAX_PROBLEMS_PER_FILE:
					problems.append((stem, f"email exceeds {MAX_EMAIL_LEN} chars: {email[:40]}..."))
				continue
			seen.add(key)
			send_rows.append((email, campaign_id, opens))
			n_kept += 1

		if n_long > MAX_PROBLEMS_PER_FILE:
			problems.append((stem, f"...and {n_long - MAX_PROBLEMS_PER_FILE} more over-length emails (suppressed)"))

		print(f"{campaign_id:>4} {stem:<100} {n_read:>6} {n_kept:>6} {n_deleted:>5} {n_blank:>5} {n_dupe:>5}")

		total_deleted += n_deleted
		total_blank += n_blank
		total_dupes += n_dupe
		total_long += n_long
		if n_kept == 0:
			# Zero valid emails from a real campaign file is never plausible.
			problems.append((stem, f"ZERO valid emails kept (read {n_read}, delimiter={delim!r})"))

	# --------------------------------------------------------- write out ---
	# newline='' + explicit \r\n lineterminator: must match the LOAD DATA
	# clause exactly or MySQL loads zero rows without complaint.
	OUT_DIR.mkdir(parents=True, exist_ok=True)

	with open(OUT_CAMPAIGNS, "w", newline="", encoding="utf-8") as f:
		w = csv.writer(f, lineterminator="\r\n", quoting=csv.QUOTE_MINIMAL)
		w.writerow(["campaign_id", "campaign_name", "campaign_date"])
		w.writerows(campaign_rows)

	with open(OUT_SENDS, "w", newline="", encoding="utf-8") as f:
		w = csv.writer(f, lineterminator="\r\n", quoting=csv.QUOTE_MINIMAL)
		w.writerow(["contact_email", "campaign_id", "opens"])
		w.writerows(send_rows)

	print("-" * 138)
	print(f"files processed : {len(files)}")
	print(f"campaigns       : {len(campaign_rows)} \t->  {OUT_CAMPAIGNS}")
	print(f"sends           : {len(send_rows)} \t->  {OUT_SENDS}")
	try:
		mb = OUT_SENDS.stat().st_size / (1024 * 1024)
		print(f"sends.csv size  : {mb:.1f} MB")
	except OSError:
		pass
	print(f"dropped         : {total_deleted} deleted-sentinel, {total_blank} blank, {total_dupes} duplicate, {total_long} over-length")

	if problems:
		print(f"\n*** {len(problems)} PROBLEM(S) -- output written but treat this run as FAILED until reviewed: ***")
		for name, desc in problems:
			print(f"  - {name}: {desc}")
		return 1
	if not send_rows:
		print("\n*** FATAL: zero send rows written. ***")
		return 1
	print("\nOK.")
	return 0


if __name__ == "__main__":
	sys.exit(main())