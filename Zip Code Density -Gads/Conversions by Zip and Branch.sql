# Finding conversions by zip code
with conversion as (
select c.phone1, c.zip, c.officeID, s.subscriptionID, c.customerID
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on s.customerID = c.customerID
where year(c.dateAdded) >= 2021 and c.status = 1 and s.initialStatus = 1 #and c.source like "%internet%"
group by customerID
), billable as (
select c.contact_number_clean
from dwh_ctmdb.calls as c
where sale_billable = "billable" and year(dateContacted) >= 2021
)

select count(c.customerID) as conversions, c.zip, o.branchName
from billable as b
inner join conversion as c on b.contact_number_clean = c.phone1
left join dwh_reportsdb.office as o on c.officeID = o.officeID
group by zip
order by count(c.customerID) desc, o.branchName desc
;

# Finding zip codes
select c.zip, c.customerid
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on s.customerID = c.customerid
where c.status = 1 and s.initialstatus = 1 and length(c.zip) = 5
group by c.zip
