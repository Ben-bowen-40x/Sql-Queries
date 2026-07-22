"""
build_email_campaigns.py

Consolidates all campaign-list CSV exports into a single email_campaigns.csv
for ingestion by the MySQL temporary table `email_campaigns` via
LOAD DATA LOCAL INFILE.

Output columns: contact_email, campaign_name, campaign_date (YYYY-MM-DD)

Design notes (load-bearing decisions):
- campaign_name is the FULL filename stem (no .csv). The date prefix stays in
  the name on purpose: resends, "_1"/"_2" variants, and "Batch #N" files must
  remain distinct under the (contact_email, campaign_name) primary key.
  NOTE: longest observed name is ~97 chars -> the table column must be at
  least VARCHAR(150), not VARCHAR(50). The script hard-fails if any name
  exceeds MAX_CAMPAIGN_NAME_LEN so the mismatch can never truncate silently.
- Files whose name contains "test" (case-insensitive) are excluded, per spec.
- The email column is found by EXACT (case-insensitive, whitespace-stripped)
  header match on "Email". Substring matching would wrongly hit "Email 2",
  "Reply email", or "Email Client", which all exist in these exports.
- "[Subscriber Deleted]" rows and blank emails are dropped. Duplicate emails
  within a file are deduped (case-insensitive) to avoid PK violations that
  would abort LOAD DATA mid-file.
- Delimiter is sniffed per file (comma vs tab) because some Excel exports of
  these lists have shipped as tab-delimited despite the .csv extension.
- Encoding: BOM-sniffed UTF-16 -> UTF-8(-sig) -> cp1252 fallback. Output is
  plain UTF-8, no BOM. (A BOM would only pollute the header line, which
  IGNORE 1 LINES skips, but no reason to write one.)
- Output line terminator is explicitly \r\n to match LINES TERMINATED BY
  '\r\n'. A terminator mismatch makes LOAD DATA ingest ZERO rows with no
  error -- the classic silent failure -- so this is pinned, not defaulted.
- Loud-failure policy: any file with a missing Email column, an unparseable
  date, or zero valid emails is reported and the script exits nonzero so the
  batch wrapper can flag it. Per-file counts are printed as a plausibility
  check either way.
"""

import csv
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------- config ---
SRC_DIR = Path(r"C:\Users\benjamin.bowen\Repos\Sql-Queries\Code\Recurring\Campaign lists")
OUT_FILE = Path(r"C:\Users\benjamin.bowen\Repos\Sql-Queries\Code\Recurring\email_campaigns.csv")

MAX_CAMPAIGN_NAME_LEN = 200                  # size the DDL column to match: VARCHAR(200)
MAX_EMAIL_LEN = 100                          # matches contact_email VARCHAR(100)
DELETED_SENTINEL = "[subscriber deleted]"    # compared lowercase

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


def find_email_col(headers):
    """Exact match on 'Email' only. Returns (index, warning_or_None)."""
    matches = [i for i, h in enumerate(headers) if h.strip().lower() == "email"]
    if not matches:
        return None, "no header exactly matching 'Email'"
    warn = None
    if len(matches) > 1:
        warn = f"multiple 'Email' headers at columns {matches}; using first"
    return matches[0], warn


# ------------------------------------------------------------------ main ---
def main() -> int:
    if not SRC_DIR.is_dir():
        print(f"FATAL: source directory not found: {SRC_DIR}")
        return 1

    files = sorted(
        p for p in SRC_DIR.glob("*.csv")
        if "test" not in p.stem.lower()
    )
    if not files:
        print(f"FATAL: no non-test .csv files found in {SRC_DIR}")
        return 1

    out_rows = []
    problems = []          # (filename, description) -> nonzero exit
    total_deleted = 0
    total_blank = 0
    total_dupes = 0

    print(f"{'file':<100} {'read':>6} {'kept':>6} {'del':>5} {'blank':>5} {'dupe':>5}")
    print("-" * 132)

    for path in files:
        stem = path.stem

        if len(stem) > MAX_CAMPAIGN_NAME_LEN:
            problems.append((stem, f"campaign name is {len(stem)} chars, "
                                   f"exceeds {MAX_CAMPAIGN_NAME_LEN}"))
            continue

        campaign_date = parse_campaign_date(stem)
        if campaign_date is None:
            problems.append((stem, "could not parse leading MM.DD.YYYY date"))
            continue

        text = decode_bytes(path.read_bytes())
        lines = text.splitlines()
        if not lines:
            problems.append((stem, "file is empty"))
            continue

        delim = sniff_delimiter(lines[0])
        reader = csv.reader(lines, delimiter=delim)
        try:
            headers = next(reader)
        except StopIteration:
            problems.append((stem, "no header row"))
            continue

        email_idx, warn = find_email_col(headers)
        if email_idx is None:
            problems.append((stem, warn))
            continue
        if warn:
            print(f"  WARN [{stem}]: {warn}")

        seen = set()
        n_read = n_kept = n_deleted = n_blank = n_dupe = 0

        for row in reader:
            n_read += 1
            email = (row[email_idx].strip() if email_idx < len(row) else "")
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
                problems.append((stem, f"email exceeds {MAX_EMAIL_LEN} chars: "
                                       f"{email[:40]}..."))
                continue
            seen.add(key)
            out_rows.append((email, stem, campaign_date))
            n_kept += 1

        print(f"{stem:<100} {n_read:>6} {n_kept:>6} {n_deleted:>5} "
              f"{n_blank:>5} {n_dupe:>5}")

        total_deleted += n_deleted
        total_blank += n_blank
        total_dupes += n_dupe

        if n_kept == 0:
            # Zero valid emails from a real campaign file is never plausible.
            problems.append((stem, f"ZERO valid emails kept "
                                   f"(read {n_read}, delimiter={delim!r})"))

    # --------------------------------------------------------- write out ---
    # newline='' + explicit \r\n lineterminator: must match the LOAD DATA
    # clause exactly or MySQL loads zero rows without complaint.
    OUT_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_FILE, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, lineterminator="\r\n", quoting=csv.QUOTE_MINIMAL)
        w.writerow(["contact_email", "campaign_name", "campaign_date"])
        w.writerows(out_rows)

    print("-" * 132)
    print(f"files processed : {len(files)}")
    print(f"rows written    : {len(out_rows)}  ->  {OUT_FILE}")
    print(f"dropped         : {total_deleted} deleted-sentinel, "
          f"{total_blank} blank, {total_dupes} duplicate")

    if problems:
        print(f"\n*** {len(problems)} PROBLEM(S) -- output written but "
              f"treat this run as FAILED until reviewed: ***")
        for name, desc in problems:
            print(f"  - {name}: {desc}")
        return 1

    if not out_rows:
        print("\n*** FATAL: zero rows written. ***")
        return 1

    print("\nOK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
