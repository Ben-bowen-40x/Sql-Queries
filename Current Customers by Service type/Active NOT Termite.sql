select 
	c.email as "Email", c.fname as "First Name", c.lname as "Last Name", 
    "United States" as "Country", 
    c.zip as "Zip", 
    "" as "Email2", "" as "Zip2", 
    c.phone1 as "Phone", c.phone2 as "Phone2"
    , s.servicetype, s.customerid, s.subscriptionid, s.active
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.customer as c on c.customerid = s.customerid
where c.status = 1
group by c.customerid, c.email
-- ,
-- servicetype
having sum(s.servicetype in (
        -- Termites
        'Termite - Liquid','NE - Sentricon','Termite Warranty','Sentricon','Termite Pretreat','NE - Sentricon OnSite Inspection','Termite - Sentricon Always Active Protection - Annual Termite Inspection',
        'NE - Sentricon - Initial/Paperwork','Sentricon - Install','NE - Sentricon - Ground Install','Sentricon OnSite Inspection','Termite - Sentricon Always Active Protection - Install',
        'Sentricon - Initial/Paperwork','Sentricon QA Visit','TESTING - IT use only','TESTING 2 - IT use only'
        ) and s.active = 1
) = 0
;

/*
-- Service Type lists
select serviceType
from dwh_reportsdb.subscription
group by serviceType
*/