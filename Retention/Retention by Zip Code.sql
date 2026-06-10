SELECT z.zip, o.branchName, count(distinct(c.customerid)) neverCancelled
FROM dwh_census.census_by_zip as z
left join dwh_reportsdb.customer as c on c.zip = z.zip
left join dwh_reportsdb.subscription as s on c.customerID = s.customerID
left join dwh_reportsdb.office as o on o.officeID = z.officeID
where year(s.dateCancelled) = 0 and 
z.officeID is not null
group by z.zip;

SELECT z.zip, o.branchName, count(distinct(c.customerid)) cancelled
FROM dwh_census.census_by_zip as z
left join dwh_reportsdb.customer as c on c.zip = z.zip
left join dwh_reportsdb.subscription as s on c.customerID = s.customerID
left join dwh_reportsdb.office as o on o.officeID = z.officeID
where year(s.dateCancelled) > 0 and 
z.officeID is not null
group by z.zip;

# current zip codes with customers
select zip, officeID from dwh_census.census_by_zip where officeID is not null and officeID>0
group by zip