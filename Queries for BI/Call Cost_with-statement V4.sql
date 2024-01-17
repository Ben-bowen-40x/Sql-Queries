with calls as (
SELECT month(c.dateContacted) as "Month", year(c.dateContacted) as "Year", c.call_id as "Number", c.source as "Source", o.branchName as "Branch"
FROM dwh_ctmdb.calls as c
left join dwh_reportsdb.office as o
	on o.officeID = c.officeID
WHERE year(c.dateContacted) = 2023
and c.sale_billable = 'billable'
),
subs as (
SELECT u.phone1 as "Number", s.serviceType as "Service"
from dwh_reportsdb.subscription s 
left join dwh_reportsdb.customer u
	on s.customerID = u.customerID
)
select c.Year, c.Month, c.Number, c.Source, c.Branch, s.Service
from calls c
left join subs s
	on s.Number = c.Number
#group by c.Year, c.Month, c.Source, c.Branch, s.Service