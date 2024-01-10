select c.fullName, c.phone1, c.email
from dwh_reportsdb.subscription s
left join dwh_reportsdb.customer c on s.customerID = c.customerID
where c.status = 1 and s.initialStatus = 1
group by s.customerID