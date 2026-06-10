with subs as (
select customerID, serviceType
from dwh_reports.subscription
)

select c.fullName as 'Full Name', c.email as 'Email', c.phone1 as 'Phone Number'#, serviceType
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.customer as c on c.customerID = s.customerID
where c.status = 1 and length(c.email) > 4
	and s.serviceType not like "%Home Protection Plan%" 
group by phone1