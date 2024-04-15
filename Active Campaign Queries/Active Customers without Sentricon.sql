select c.fullName, c.phone1, c.email
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on c.customerID = s.customerID
where c.status > 0 and c.statusText = "Active" 
	and (s.serviceType not like "%yard Enjoyment Plan%" and s.serviceType not like "%yard%" and s.initialStatus > 0)
	and email is not null and email != ''
group by email, phone1