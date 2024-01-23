select c.fullName, c.phone1, c.email
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on c.customerID = s.customerID
where c.status > 0 and c.statusText = "Active" and (s.serviceType not like "%sentricon%" and s.serviceType not like "%termite%" and s.initialStatus > 0)