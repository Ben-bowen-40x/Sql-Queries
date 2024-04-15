select c.email as "Email", c.fname as "First Name", c.lname as "Last Name", "United States" as "Country", c.zip as "Zip Code", c.phone1 as "Primary Phone", c.phone2 as "Secondary Phone"
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on c.customerID = s.customerID
where c.status > 0 and c.statusText = "Active" and (s.serviceType like "%sentricon%" and s.serviceType like "%termite%" and s.initialStatus > 0)