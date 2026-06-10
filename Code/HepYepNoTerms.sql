-- Code Crew: 30-day email subscribers who have HPP or YEP but NOT Termite

select
    if(c.status = 1, "Active", "Inactive") as `Active Status`, -- This ensures that the customers we're looking for haven't cancelled
    c.customerid as `Customer Id`, s.subscriptionid as `Subscription Id`,
    c.email as `Email`, 
    c.phone1 as `Phone`, 
    c.dateadded as `Start Date`,
    s.servicetype as `Service Type`,
    count(s.subscriptionid) as `Subscription Count`
    -- , c.officeid
    -- , c.*,s.*
from dwh_reportsdb.customer c
left join dwh_reportsdb.subscription s 
	on s.customerid = c.customerid
	-- and (s.dateadded >= curdate() - interval 90 day)
where
	-- (s.dateadded >= curdate() - interval 90 day) and 
    length(c.email) >= 5
    and c.status = 1 -- This ensures the customer isn't cancelled
    /*Limiting branches
    and c.officeid in ( 
		-- Texas
        0,7,10,11,12,25
        , #Louisiana
        4,9,12,19,23,25,28,36,38
        , #Florida
        28,38
        )#*/
group by c.customerid, c.email, c.phone1, c.dateadded
having sum(case when (s.servicetype like "%termite%" or s.servicetype like "%sentricon%") then 1 else 0 end) = 0
	and sum(case when (s.servicetype like "%home protection%" /*or s.servicetype like "%yard enjoyment%"*/) then 1 else 0 end) > 0
;

/*Looking for office ids
select *
from dwh_reportsdb.office
 where branchName like "%FL%"
group by officeid
;#*/

/* Looking for service types
select servicetype
from dwh_reportsdb.subscription as s
group by servicetype
;#*/

/* Looking for source
select source 
from dwh_reportsdb.subscription
group by source
;#*/