SELECT contact_number_clean, called_at, duration, note, sale_billable, source
FROM dwh_ctmdb.calls
WHERE dateContacted between "2023-10-01" and CURDATE() and source = "WGL" 
;