with calls as (
SELECT 
	month(c.dateContacted) as "Month", year(c.dateContacted) as "Year", c.contact_number_clean as "Number", 
	c.source as "Source", o.branchName as "Branch"
FROM dwh_ctmdb.calls as c
left join dwh_reportsdb.office as o
	on o.officeID = c.officeID
WHERE year(c.dateContacted) = 2023
and c.sale_billable = 'billable'
)
select c.Year, c.Month, c.Source, c.Branch, s.serviceType as "Service", count(c.Number) as Calls
from calls c
left join dwh_reportsdb.customer u on c.Number = u.phone1
left join dwh_reportsdb.subscription s on s.customerID = u.customerID
group by c.Year, c.Month, c.Source, c.Branch, s.serviceType