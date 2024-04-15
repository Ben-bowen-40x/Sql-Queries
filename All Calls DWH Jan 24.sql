select call_id, account_id, name, called_at, contact_number, call_status, duration, audio, current_customer, location, referrer, campaign, city, state, country, sale_billable,
sale_score, sale_conversion, sale_value, sale_date, snapshotDate, dateContacted, source, codeBlue, codeRed, codeGreen, contact_number_clean, in_database, weekDay, time_zone, called_at_utc, called_at_denver, original_billable,
tracking_number, numbers_name, officeID, original_source, zip, branch
from dwh_ctmdb.calls as c
where year(dateContacted) = 2024 and month(dateContacted) = 1