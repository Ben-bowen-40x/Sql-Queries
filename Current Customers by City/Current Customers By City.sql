with rankedCustomers as ( 
select c.customerID, c.officeID, city, state, dense_rank() over ( partition by c.customerID order by s.subscriptionID desc ) as ranking
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on s.customerID = c.customerID
where c.statusText = "Active" and s.initialStatus = true
group by c.customerID
),

cities as (SELECT c.customerID, o.branchName as Branch, c.city as City, c.state as State, count(c.customerID) as Customers
FROM rankedCustomers as c 
left join dwh_reportsdb.office as o on c.officeID = o.officeID
where c.ranking = 1
group by branch, city)

select c.Branch, c.City, c.State, c.Customers
from cities as c
left join rankedCustomers as r on r.customerID=c.customerID
where c.Customers > 25;

use dwh_reportsdb;