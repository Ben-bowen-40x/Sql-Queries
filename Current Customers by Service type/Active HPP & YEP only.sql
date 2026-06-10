with customer as (
select c.customerid, c.status,
	c.email, c.fname, c.lname, c.zip, c.phone1, c.phone2, 
    s.servicetype, s.subscriptionid
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.customer as c on c.customerid = s.customerid
)

/*
select * 
from dwh_reportsdb.customer as c
left join dwh_reportsdb.subscription as s on s.customerid = c.customerid
group by s.subscriptionid
having sum(case when s.servicetype in  (
		-- HPP
		'Home Protection Plan','Home Protection Plan - ORGANIC','Fox Home Protection Plan - ORGANIC','Fox Home Protection Plan','Home Protection Plan - Initial','Organic HPP',
        'Fox Home Protection Plan - Initial','Fox Home Protection Plan - PEST TUBES','Fox Home Protection Plan - ORGANIC INITIAL'
        ,
        -- YEP
        'Yard Enjoyment Plan - ORGANIC','Yard Enjoyment Plan','Initial YPP Monthly Yard Protection Plan','Yard Enjoyment Plan - Initial','Single Service YEP','Yard Enjoyment Plan - ORGANIC Initial'
        ) then 1 else 0 end) =0
;*/
        
select c.email as "Email", c.fname as "First Name", c.lname as "Last Name", "United States" as "Country", c.zip as "Zip", "" as "Email2", "" as "Zip2", c.phone1 as "Phone", c.phone2 as "Phone2",
	c.servicetype, c.subscriptionid, c.customerid, count(c.serviceType)
from customer as c
where 
/*exists(
	select 1 
    from dwh_reportsdb.subscription as s
    where s.customerid = c.customerid
		and s.serviceType in (
		-- HPP
		'Home Protection Plan','Home Protection Plan - ORGANIC','Fox Home Protection Plan - ORGANIC','Fox Home Protection Plan','Home Protection Plan - Initial','Organic HPP',
        'Fox Home Protection Plan - Initial','Fox Home Protection Plan - PEST TUBES','Fox Home Protection Plan - ORGANIC INITIAL'
        ,
        -- YEP
        'Yard Enjoyment Plan - ORGANIC','Yard Enjoyment Plan','Initial YPP Monthly Yard Protection Plan','Yard Enjoyment Plan - Initial','Single Service YEP','Yard Enjoyment Plan - ORGANIC Initial'
        )
		and s.initialStatus = 1
) and */
not exists(
	select s.serviceType
    from dwh_reportsdb.subscription as s
    where s.customerid = c.customerid and 
		s.serviceType in (
        -- Termites
        'Termite - Liquid','NE - Sentricon','Termite Warranty','Sentricon','Termite Pretreat','NE - Sentricon OnSite Inspection','Termite - Sentricon Always Active Protection - Annual Termite Inspection',
        'NE - Sentricon - Initial/Paperwork','Sentricon - Install','NE - Sentricon - Ground Install','Sentricon OnSite Inspection','Termite - Sentricon Always Active Protection - Install',
        'Sentricon - Initial/Paperwork','Sentricon QA Visit'
        )
		and s.initialStatus = 1
)
and c.status = 1
group by c.serviceType;



select 
/*
-- Service Type lists
select serviceType
from dwh_reportsdb.subscription
group by serviceType
*/