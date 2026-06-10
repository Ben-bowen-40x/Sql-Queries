#/* Self: This code is intended to find subscriptions attributed to IM since 2019 and find the money invoiced to that customer, which is theoretically the amount paid to us by that customer

with calls as ( -- Use unfiltered calls because later we will connect these to subscriptions by phone number, which should eliminate subscriptions that were not won by IM efforts
select *
from dwh_ctmdb.calls 
where year(datecontacted) >= '2019-08-01' -- Self: As far as I can tell, I'm only putting this here for peace of mind --> this filter probably doesn't really matter because Fox CTM didn't exist prior to this particular month and year anyway, and if it did, it's not connecting
), subCustomers as (
select 
	c.customerid, s.subscriptionid, coalesce(phone1, phone2) as phone, 
    c.dateadded as custdate, s.dateadded as subdater, s.dateCancelled,
	dense_rank() over(partition by s.customerid order by s.dateadded) as ranking
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.customer as c on s.customerid = c.customerid
where s.initialstatus = 1 
	-- Don't filter this to those after 2019 because we will do it with the calls connection
), ticketCredits as (
select t.subtotal, c.creditamount, t.active, t.connectedsubscription, t.invoicedate
from dwh_reportsdb.ticket as t
left join dwh_reportsdb.subscription_credit_memos as c on c.connectedsubscription = t.connectedsubscription
where t.active = 1
), filteredsubs as (
select s.subscriptionid, s.customerid, 
	c.source,
	if(s.subdater < s.custdate, 
      date_add(s.subdater, interval 1 hour), 
      date_add(s.custdate, interval 1 hour)) 
	as addedDate,
    s.datecancelled
from subCustomers as s
left join calls as c on c.contact_number_clean = s.phone
where year(s.subdater) >= 2019
	and contact_number_clean is not null
-- Ensure that the subscription began on or before the same day of the call
	and day(s.subdater) >= day(called_at_denver) and month(s.subdater) = month(called_at_denver) and year(s.subdater) = year(called_at_denver)
-- Ensure that the customer began on or before the same day of the call
    and day(s.custdate) >= day(called_at_denver) and month(s.custdate) = month(called_at_denver) and year(s.custdate) = year(called_at_denver)
-- Remove repeated subscriptions from the same customer, because IM can only reasonably take credit for 1 subscription at a time
	and ranking = 1
group by s.subscriptionid
), everything as (
select s.subscriptionid, s.addedDate, t.creditamount, t.subtotal, t.invoiceDate, s.source
from filteredsubs as s
left join ticketCredits as t on t.connectedSubscription = s.subscriptionid
), roi as ( -- This is just associating spend with a specific year
select 
	case 
		when year(called_at_denver) = 2019 then 339813.29
        when year(called_at_denver) = 2020 then 2268311.84
        when year(called_at_denver) = 2021 then 1647249.32
        when year(called_at_denver) = 2022 then 5500000.00
        when year(called_at_denver) = 2023 then 5548772.57
        when year(called_at_denver) = 2024 then 5000000.00
        else 0
        end as Spend,
	year(called_at_denver) as year
from calls
group by year(called_at_denver)
)

/* This is a direct statement for all records
select *
from everything
;*/

/* This is a select statement that tests the connection between tickets and subscriptions
-- This query is designed for finding line-by-line accounts AND for aggregates, which is why subscriptionid and addeddate are both selected in this statement
select 
    concat('$', format(sum(subtotal) + sum(creditamount), 2)) as paid, -- 'Concat' and 'format' are being used for readability because it's hard to read numbers in the millions
    concat('$', format(r.spend, 2)) as spend,
    year(invoicedate) as year
from everything as t
left join roi as r on r.year = year(t.invoicedate)
where year(invoicedate) is not null and year(invoiceDate) >= 2019 -- This cleans up the results
group by year(invoicedate);
#*/

/* This is a select statement that tests the connection between tickets and subscriptions
-- This query is designed for finding line-by-line accounts
select 
	subscriptionid, 
    addeddate,
    year(addeddate),
    concat('$', format(subtotal + creditamount, 2)) as paid, -- 'Concat' and 'format' are being used for readability because it's hard to read numbers in the millions
    concat('$', format(r.spend, 2)) as spend,
    year(invoicedate) as year    
from everything as t
left join roi as r on r.year = year(t.invoicedate)
where year(invoicedate) is not null and year(invoiceDate) >= 2019 -- This cleans up the results
group by year(invoicedate);
#*/
