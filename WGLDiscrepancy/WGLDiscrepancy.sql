SELECT contact_number_clean, called_at, duration, note, sale_billable, source
FROM dwh_ctmdb.calls
WHERE year(called_at) ="2023" and month(called_at)= in("07,08")