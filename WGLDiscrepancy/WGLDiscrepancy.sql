SELECT contact_number_clean, called_at, duration, note, source,
case
	when sale_billable = 'billable' then 'true'
    else 'false'
    end as 'billable'
FROM dwh_ctmdb.calls
WHERE dateContacted between '2023-10-01' and CURDATE() and source = 'WGL'
;