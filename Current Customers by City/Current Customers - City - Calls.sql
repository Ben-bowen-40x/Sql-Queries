with rankedCustomers as ( 
select c.phone1, c.phone2, c.customerID, c.officeID, city, state, dense_rank() over ( partition by c.customerID order by s.subscriptionID desc ) as ranking
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on s.customerID = c.customerID
where c.statusText = "Active" and s.initialStatus = true
group by c.customerID
),

cities as (SELECT c.customerID, o.branchName as Branch, c.city as City, c.state as State, count(c.customerID) as Customers
FROM rankedCustomers as c 
left join dwh_reportsdb.office as o on c.officeID = o.officeID
where c.ranking = 1
group by branch, city),

calls as (
select contact_number_clean as number, source
from dwh_ctmdb.calls as cc
where dateContacted between '2023-03-01' and '2023-11-06' and source like '%Google Organic%'
)

select c.Branch, c.City, c.State, c.Customers, count(cc.number) as "Organic Customers"
from cities as c
left join rankedCustomers as r on r.customerID=c.customerID
left join calls as cc on r.phone1 = cc.number or r.phone2 = cc.number
where c.Customers > 25
group by c.City;

use dwh_reportsdb;