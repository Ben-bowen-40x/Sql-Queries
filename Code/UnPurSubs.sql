-- Code Crew: 30-day email subscribers who have not yet purchased
-- (whatever that means)

select
    if(c.status = 1, "Active", "Inactive") as `Active Status`, -- This ensures that the customers we're looking for haven't cancelled
    c.customerid as `Customer Id`, s.subscriptionid as `Subscription Id`,
    c.email as `Email`, 
    c.phone1 as `Phone`, 
    c.dateadded as `Start Date`,
    max(s.initialstatus) as `Received Initial`, -- for reference
    count(s.subscriptionid) as `Subscription Count`
from dwh_reportsdb.customer c
left join dwh_reportsdb.subscription s 
	on s.customerid = c.customerid
	and (s.dateadded >= curdate() - interval 90 day)
where
	(s.dateadded >= curdate() - interval 90 day)
    and length(c.email) >= 5
    and c.status = 1 -- This ensures the customer isn't cancelled
    and subscriptionid is null
group by c.customerid, c.email, c.phone1, c.dateadded
having sum(case when s.initialstatus = 1 then 1 else 0 end) = 0
;
