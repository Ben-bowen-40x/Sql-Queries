-- Code Crew: All subscribers who have HPP

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
where length(c.email) >= 5
    and c.status = 1 -- This ensures the customer isn't cancelled
    and s.active = 1
    -- /* Limit type
    and serviceType in (
    # HPP
    "Fox Home Protection Plan","Fox Home Protection Plan - Initial","Fox Home Protection Plan - ORGANIC","Home Protection Plan","Home Protection Plan - Initial","Home Protection Plan - ORGANIC"
    -- ,
    )
    #*/
    /* Limiting start dates
    and least(c.dateadded, s.dateadded) >= date_sub(now(), interval 60 day)
    #*/
    /*Limiting branches
    and c.officeid in ( 
		-- Texas
        0,7,10,11,12,25,
        -- Louisiana
        4,9,12,19,23,25,28,36,38,
        -- Florida
        28,38
        )#*/
group by c.email
;

select serviceType
from dwh_reportsdb.subscription
where dateadded >= "2025-01-01"
group by serviceType
order by serviceType asc