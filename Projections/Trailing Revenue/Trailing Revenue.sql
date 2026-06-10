#Original query 
#This query is intended to retrieve and then aggregate the customer count and contract value

with c2021 as (
select 
	c.customerID,
	c.dateAdded, 
    s.dateAdded, 
    s.dateCancelled, 
    c.dateCancelled, 
    s.contractValue as "CV21"
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on s.customerID = c.customerID
where year(s.dateAdded) = 2021 and s.initialStatus = 1
	and s.source like "%internet%"
#group by c.customerID
)
#/*
, c2022 as (
select 
	c.customerID,
	c.dateAdded, 
    s.dateAdded, 
    s.dateCancelled, 
    c.dateCancelled, 
    s.contractValue as "CV22"
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on s.customerID = c.customerID
where year(s.dateAdded) = 2021 and s.initialStatus = 1
	and year(s.dateCancelled) not in(2021)
    and s.source like "%internet%"
#group by c.customerID
)
#/*
, c2023 as (
select 
	c.customerID,
	c.dateAdded, 
    s.dateAdded, 
    s.dateCancelled, 
    c.dateCancelled, 
    s.contractValue as "CV23"
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on s.customerID = c.customerID
where year(s.dateAdded) = 2021 and s.initialStatus = 1
	and year(s.dateCancelled) not in(2021, 2022)
    and s.source like "%internet%"
#group by c.customerID
)
#*/

select 
	count(c21.customerID) as "cust21", sum(c21.cv21),
	count(c22.customerID) as "cust22", sum(c22.cv22),
    count(c23.customerID) as "cust23", sum(c23.CV23)    
 from c2021 as c21
 left join c2022 as c22 on c21.customerID = c22.customerID
 left join c2023 as c23 on c21.customerID = c23.customerID
 