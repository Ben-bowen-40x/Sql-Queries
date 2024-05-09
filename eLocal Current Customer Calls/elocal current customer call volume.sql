with elocal as (
select contact_number_clean as 'CallerID', duration as 'CallDurationSeconds', date(called_at_utc) as 'CallerDate'
from dwh_ctmdb.calls 
where source like "%elocal%" and year(called_at_utc) = 2024
),
customers as (
select phone1 as 'CustomerPhone', date(dateAdded) as 'DateCallerBecameCustomer'
from dwh_reportsdb.customer
where status = 1
),
elocalcustomer as (
select *
from elocal as e
left join customers as c on e.CallerID = c.CustomerPhone
)

select *
from elocalcustomer
where DateCallerBecameCustomer < CallerDate and CallDurationSeconds >= 90

