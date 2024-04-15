select 
	c.contact_number_clean as "PhoneNumber", c.dateContacted as "CallDate", 
    o.branchname as "Branch", c.source as "Source", u.customerID as "CustomerId"
from dwh_ctmdb.calls as c
	left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
    left join dwh_reportsdb.office as o on o.officeID = c.officeID
where c.sale_billable = "billable" and year(dateContacted) = 2023