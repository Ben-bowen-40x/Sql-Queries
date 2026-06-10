with customers as (
select c.zip, c.customerID, o.branchName
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on s.customerID = c.customerID
left join dwh_reportsdb.office as o on c.officeID = o.officeID
where s.initialStatus = 1 
#and year(c.dateAdded) = 2024 
group by customerID
)

select count(customerID) as customers, zip, branchName
from customers
#where branchName like "%boston%"
group by zip
order by 
count(customerID) desc,
 branchName asc
