SELECT contact_number_clean, called_at, dateContacted, note, zip
FROM dwh_ctmdb.calls
WHERE called_at BETWEEN '2023-01-01' AND '2023-08-31'
AND (zip = "23608" OR zip = "06880" OR zip = "02562" OR zip = "78584" OR zip = "32804" OR zip = "32811")