with ordered as (
select contact_number_clean, sale_billable, called_at_utc, rank() over (partition by contact_number_clean order by called_at_utc asc) as num_repeated
from dwh_ctmdb.calls as c
where contact_number_clean is not null
and year(called_at_utc) in (2024)
#and month(called_at_utc) in (2,3,4,5,6,7,8,9)
order by called_at_utc asc
)

select *
from ordered
where #num_repeated > 1 and 
sale_billable = "billable"