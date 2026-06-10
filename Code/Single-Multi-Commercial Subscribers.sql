-- Customers who started between specific dates
-- Filters for current customers

-- Query 1: Active customers who started within the last 30 days and only have 1 subscription
select  
	if(c.status = 1, "Active", "Inactive") as `Active Status`, -- This ensures that the customers we're looking for haven't cancelled
    c.customerid as `Customer Id`, s.subscriptionid as `Subscription Id`,
    c.email as `Email`, 
    c.phone1 as `Phone`, 
    c.dateadded as `Start Date`,
    max(s.initialstatus) as `Received Initial`, -- for reference
    count(s.subscriptionid) as `Subscription Count`
from dwh_reportsdb.customer as c 
left join dwh_reportsdb.subscription as s on s.customerid = c.customerid
where 
-- /* Start date filter
	if(c.dateadded > s.dateadded, s.dateadded, c.dateadded) > date_sub(now(), interval 30 day) #*/
/* Cancel date filter
    s.datecancelled between '2026-02-08' and now() #*/
# Commercial filter
    and s.commercialAccount <> 1
-- # Active filter and initialstatus filter
    and s.active = 1 and c.status = 1 and s.initialStatus = 1 # */
group by c.customerid, c.email, c.phone1
-- /* Having Filter
having 
-- /* Customer has less than 2 subscriptions and is not a commercial account
	count(s.subscriptionid) < 2 and sum(case when s.commercialAccount = 1 then 1 else 0 end) = 0 #*/
/* Customer has more than 1 subscription and is not a commercial account
    count(s.subscriptionid) > 1 and sum(case when s.commercialAccount = 1 then 1 else 0 end) = 0 #*/
/* Customer is a commercial account
    sum(case when s.commercialAccount = 1 then 1 else 0 end) = 1 #*/
;

-- Query 2: Active customers who started within the last 30 days and have more than 1 subscription
select  
	if(c.status = 1, "Active", "Inactive") as `Active Status`, -- This ensures that the customers we're looking for haven't cancelled
    c.customerid as `Customer Id`, s.subscriptionid as `Subscription Id`,
    c.email as `Email`, 
    c.phone1 as `Phone`, 
    c.dateadded as `Start Date`,
    max(s.initialstatus) as `Received Initial`, -- for reference
    count(s.subscriptionid) as `Subscription Count`
from dwh_reportsdb.customer as c 
left join dwh_reportsdb.subscription as s on s.customerid = c.customerid
where 
-- /* Start date filter
	if(c.dateadded > s.dateadded, s.dateadded, c.dateadded) > date_sub(now(), interval 30 day) #*/
/* Cancel date filter
    s.datecancelled between '2026-02-08' and now() #*/
# Commercial filter
    and s.commercialAccount <> 1
-- # Active filter and initialstatus filter
    and s.active = 1 and c.status = 1 and s.initialStatus = 1 # */
group by c.customerid, c.email, c.phone1
-- /* Having Filter
having 
/* Customer has less than 2 subscriptions and is not a commercial account
	count(s.subscriptionid) < 2 and sum(case when s.commercialAccount = 1 then 1 else 0 end) = 0 #*/
-- /* Customer has more than 1 subscription and is not a commercial account
    count(s.subscriptionid) > 1 and sum(case when s.commercialAccount = 1 then 1 else 0 end) = 0 #*/
/* Customer is a commercial account
    sum(case when s.commercialAccount = 1 then 1 else 0 end) = 1 #*/
;

-- Query 3: Active customers who are commercial accounts
select  
	if(c.status = 1, "Active", "Inactive") as `Active Status`, -- This ensures that the customers we're looking for haven't cancelled
    c.customerid as `Customer Id`, s.subscriptionid as `Subscription Id`,
    c.email as `Email`, 
    c.phone1 as `Phone`, 
    c.dateadded as `Start Date`,
    max(s.initialstatus) as `Received Initial`, -- for reference
    count(s.subscriptionid) as `Subscription Count`
from dwh_reportsdb.customer as c 
left join dwh_reportsdb.subscription as s on s.customerid = c.customerid
where 
-- /* Start date filter
	if(c.dateadded > s.dateadded, s.dateadded, c.dateadded) > date_sub(now(), interval 30 day) #*/
/* Cancel date filter
    s.datecancelled between '2026-02-08' and now() #*/
# Commercial filter
	and s.commercialAccount = 1
-- # Active filter and initialstatus filter
    and s.active = 1 and c.status = 1 and s.initialStatus = 1 # */
group by c.customerid, c.email, c.phone1
-- /* Having Filter
having 
/* Customer has less than 2 subscriptions and is not a commercial account
	count(s.subscriptionid) < 2 and sum(case when s.commercialAccount = 1 then 1 else 0 end) = 0 #*/
/* Customer has more than 1 subscription and is not a commercial account
    count(s.subscriptionid) > 1 and sum(case when s.commercialAccount = 1 then 1 else 0 end) = 0 #*/
-- /* Customer is a commercial account
    sum(case when s.commercialAccount = 1 then 1 else 0 end) = 1 #*/
;

-- Query 4: Customers who cancelled within the last 30 days
select  
	if(c.status = 1, "Active", "Inactive") as `Active Status`, -- This ensures that the customers we're looking for haven't cancelled
    c.customerid as `Customer Id`, s.subscriptionid as `Subscription Id`,
    c.email as `Email`, 
    c.phone1 as `Phone`, 
    c.dateadded as `Start Date`,
    max(s.initialstatus) as `Received Initial`, -- for reference
    count(s.subscriptionid) as `Subscription Count`
from dwh_reportsdb.customer as c 
left join dwh_reportsdb.subscription as s on s.customerid = c.customerid
where 
/* Start date filter
	if(c.dateadded > s.dateadded, s.dateadded, c.dateadded) > date_sub(now(), interval 30 day) #*/
-- /* Cancel date filter
    s.datecancelled between '2026-02-08' and now() #*/
# Commercial filter
	-- and s.commercialAccount = 1
# Active filter and initialstatus filter
    -- and s.active = 1 and c.status = 1 and s.initialStatus = 1 # */
group by c.customerid, c.email, c.phone1
/* Having Filter
having 
/* Customer has less than 2 subscriptions and is not a commercial account
	count(s.subscriptionid) < 2 and sum(case when s.commercialAccount = 1 then 1 else 0 end) = 0 #*/
/* Customer has more than 1 subscription and is not a commercial account
    count(s.subscriptionid) > 1 and sum(case when s.commercialAccount = 1 then 1 else 0 end) = 0 #*/
/* Customer is a commercial account
    sum(case when s.commercialAccount = 1 then 1 else 0 end) = 1 #*/
;