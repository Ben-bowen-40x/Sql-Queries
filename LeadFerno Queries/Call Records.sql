SELECT contact_number_clean, called_at_utc, time_zone, sale_billable
FROM dwh_ctmdb.calls
WHERE year(called_at) = '2023'
;