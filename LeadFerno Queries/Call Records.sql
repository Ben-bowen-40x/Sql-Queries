SELECT contact_number_clean, called_at, sale_billable,
CASE
	when sale_billable = 0 then 'False'
    when sale_billable >0 then 'True'
    when sale_billable is null then 'False'
    when sale_billable = '' then 'False'
    Else 'False'
    end as 'sale_billable'
FROM dwh_ctmdb.calls
WHERE called_at like '%2023%'
;