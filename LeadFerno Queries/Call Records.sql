SELECT contact_number_clean, called_at, sale_billable
FROM dwh_ctmdb.calls
WHERE year(called_at) = '2023'
;