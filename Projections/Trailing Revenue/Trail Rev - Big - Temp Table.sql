# Self: This code is intended to find subscriptions attributed to IM since 2019 and find the money invoiced to that customer, which is theoretically the amount paid to us by that customer

-- 0.703 Run; 31.015 Fetch;
create temporary table calls as ( -- Use unfiltered calls because later we will connect these to subscriptions by phone number, which should eliminate subscriptions that were not won by IM efforts
select called_at_denver, source, contact_number_clean
from dwh_ctmdb.calls 
where datecontacted >= '2019-08-01' -- Self: As far as I can tell, I'm only putting this here for peace of mind --> this filter probably doesn't really matter because Fox CTM didn't exist prior to this particular month and year anyway, and if it did, it's not connecting
); 
-- 3.359 Run; 26.391 Fetch;
create temporary table subCustomers (
select 
	c.customerid, s.subscriptionid, coalesce(phone1, phone2) as phone, 
    c.dateadded as custdate, s.dateadded as subdater, s.dateCancelled,
	dense_rank() over(partition by s.customerid order by s.dateadded) as ranking
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.customer as c on s.customerid = c.customerid
where s.initialstatus = 1 -- Don't filter this to those after 2019 because we will do it with the calls connection
);
-- 0.141 Run; 194.891
create temporary table ticketCredits (
select t.subtotal, c.creditamount, t.active, t.connectedsubscription, t.invoicedate
from dwh_reportsdb.ticket as t
left join dwh_reportsdb.subscription_credit_memos as c on c.connectedsubscription = t.connectedsubscription
where t.active = 1
);
-- 
create temporary table filteredsubs (
select s.subscriptionid, s.customerid, 
	c.source,
	if(s.subdater < s.custdate, 
      date_add(s.subdater, interval 1 hour), 
      date_add(s.custdate, interval 1 hour)) 
	as addedDate,
    s.datecancelled
from subCustomers as s
left join calls as c on c.contact_number_clean = s.phone
where s.subdater >= '2019-01-01'
	and contact_number_clean is not null
-- Ensure that the subscription began on or before the same day of the call
	and day(s.subdater) >= day(called_at_denver) and month(s.subdater) = month(called_at_denver) and year(s.subdater) = year(called_at_denver)
-- Ensure that the customer began on or before the same day of the call
    and day(s.custdate) >= day(called_at_denver) and month(s.custdate) = month(called_at_denver) and year(s.custdate) = year(called_at_denver)
-- Remove repeated subscriptions from the same customer, because IM can only reasonably take credit for 1 subscription at a time
	and ranking = 1
group by s.subscriptionid
);
create temporary table everything (
select s.subscriptionid, s.addedDate as dateAdded, s.datecancelled, t.creditamount, t.subtotal, t.invoiceDate, s.source
from filteredsubs as s
left join ticketCredits as t on t.connectedSubscription = s.subscriptionid
);
create temporary table roi ( -- All this is doing is associating spend with a specific year
select 
	case 
		when year(called_at_denver) = 2019 then 339813.29
        when year(called_at_denver) = 2020 then 2268311.84
        when year(called_at_denver) = 2021 then 1647249.32
        when year(called_at_denver) = 2022 then 5500000.00
        when year(called_at_denver) = 2023 then 5435658 -- 5548772.57
        when year(called_at_denver) = 2024 then 5180626.00
        else 0
        end as Spend,
	year(called_at_denver) as year
from calls
group by year(called_at_denver)
);
create temporary table ag2019 (
select 
	  2019 as Year,
      339813.29 as Spend,
      count(origin.subscriptionID) as SubsOrigin, -- Year 2019
      sum(origin.contractValue) as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, -- Year 2020
      sum(stayed1Y.contractValue) as CVAfterY1,
      count(stayed2Y.subscriptionID) as SubsAfterY2, -- Year 2021
      sum(stayed2Y.contractValue) as CVAfterY2,
      count(stayed3Y.subscriptionID) as SubsAfterY3, -- Year 2022
      sum(stayed3Y.contractValue) as CVAfterY3,
      count(stayed4Y.subscriptionID) as SubsAfterY4, -- Year 2023 
      sum(stayed4Y.contractValue) as CVAfterY4,
      count(stayed5Y.subscriptionID) as SubsAfterY5, -- Year 2024
      sum(stayed5Y.contractValue) as CVAfterY5,
      count(stayed6Y.subscriptionID) as SubsAfterY6, -- Year 2025
      sum(stayed6Y.contractValue) as CVAfterY6
from (
	select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2019 and month(s.dateadded) in (8,9,10,11,12) -- They started in 2019
        and year(s.invoicedate) in (2019) -- We invoiced them in 2019
) as origin 
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2019 and month(s.dateadded) in (8,9,10,11,12) -- They started in 2019
        and year(s.invoicedate) in (2020) -- We invoiced them in 2020
) as stayed1Y on origin.subscriptionid = stayed1Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2019 and month(s.dateadded) in (8,9,10,11,12) -- They started in 2019
        and year(s.invoicedate) in (2021) -- We invoiced them in 2021
) as stayed2Y on origin.subscriptionid = stayed2Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2019 and month(s.dateadded) in (8,9,10,11,12) -- They started in 2019
        and year(s.invoicedate) in (2022) -- We invoiced them in 2022
) as stayed3Y on origin.subscriptionid = stayed3Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2019 and month(s.dateadded) in (8,9,10,11,12) -- They started in 2019
        and year(s.invoicedate) in (2023) -- We invoiced them in 2023
) as stayed4Y on origin.subscriptionid = stayed4Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2019 and month(s.dateadded) in (8,9,10,11,12) -- They started in 2019
        and year(s.invoicedate) in (2024) -- We invoiced them in 2024
) as stayed5Y on origin.subscriptionid = stayed5Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2019 and month(s.dateadded) in (8,9,10,11,12) -- They started in 2019
        and year(s.invoicedate) in (2025) -- We invoiced them in 2025
) as stayed6Y on origin.subscriptionid = stayed6Y.subscriptionid
);
create temporary table ag2020 (
select 
	  2020 as Year,
      2268311.84 as Spend,
      count(origin.subscriptionID) as SubsOrigin, -- Year 2020
      sum(origin.contractValue) as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, -- Year 2021
      sum(stayed1Y.contractValue) as CVAfterY1,
      count(stayed2Y.subscriptionID) as SubsAfterY2, -- Year 2022
      sum(stayed2Y.contractValue) as CVAfterY2,
      count(stayed3Y.subscriptionID) as SubsAfterY3, -- Year 2023
      sum(stayed3Y.contractValue) as CVAfterY3,
      count(stayed4Y.subscriptionID) as SubsAfterY4, -- Year 2024
      sum(stayed4Y.contractValue) as CVAfterY4,
      count(stayed5Y.subscriptionID) as SubsAfterY5, -- Year 2025
      sum(stayed5Y.contractValue) as CVAfterY5,
      if(count(stayed6Y.subscriptionID) = count(stayed5Y.subscriptionID), 0, count(stayed6Y.subscriptionID)) as SubsAfterY6, -- Year 2026
      if(sum(stayed6Y.contractValue) = sum(stayed5Y.contractValue), 0, sum(stayed6Y.contractValue)) as CVAfterY6
from (
	select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2020 -- They started in 2020
        and year(s.invoicedate) in (2020) -- We invoiced them in 2020
) as origin 
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2020 -- They started in 2020
        and year(s.invoicedate) in (2021) -- We invoiced them in 2021
) as stayed1Y on origin.subscriptionid = stayed1Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2020 -- They started in 2020
        and year(s.invoicedate) in (2022) -- We invoiced them in 2022
) as stayed2Y on origin.subscriptionid = stayed2Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2020 -- They started in 2020
        and year(s.invoicedate) in (2023) -- We invoiced them in 2023
) as stayed3Y on origin.subscriptionid = stayed3Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2020 -- They started in 2020
        and year(s.invoicedate) in (2024) -- We invoiced them in 2024
) as stayed4Y on origin.subscriptionid = stayed4Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2020 -- They started in 2020
        and year(s.invoicedate) in (2025) -- We invoiced them in 2025
) as stayed5Y on origin.subscriptionid = stayed5Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2020 -- They started in 2020
        and year(s.invoicedate) in (2026) -- We invoiced them in 2026
) as stayed6Y on origin.subscriptionid = stayed6Y.subscriptionid
);
create temporary table ag2021 (
   select 
	  2021 as Year,
      1647249.32 as Spend,
      15256 as SubsOrigin, -- Year 2021
      10718854 as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, -- Year 2022
      sum(stayed1Y.contractValue) as CVAfterY1,
      count(stayed2Y.subscriptionID) as SubsAfterY2, -- Year 2023
      sum(stayed2Y.contractValue) as CVAfterY2,
      count(stayed3Y.subscriptionID) as SubsAfterY3, -- Year 2024
      sum(stayed3Y.contractValue) as CVAfterY3,
      count(stayed4Y.subscriptionID) as SubsAfterY4, -- Year 2025
      sum(stayed4Y.contractValue) as CVAfterY4,
      if(count(stayed5Y.subscriptionID) = count(stayed4Y.subscriptionID), 0, count(stayed5Y.subscriptionID)) as SubsAfterY5, -- Year 2026
      if(sum(stayed5Y.contractValue) = sum(stayed4Y.contractValue), 0, sum(stayed5Y.contractValue)) as CVAfterY5,
      if(count(stayed6Y.subscriptionID) = count(stayed5Y.subscriptionID), 0, count(stayed6Y.subscriptionID)) as SubsAfterY6, -- Year 2027
      if(sum(stayed6Y.contractValue) = sum(stayed5Y.contractValue), 0, sum(stayed6Y.contractValue)) as CVAfterY6
from (
	select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2021 -- They started in 2021
        and year(s.invoicedate) in (2021) -- We invoiced them in 2021
) as origin 
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2021 -- They started in 2021
        and year(s.invoicedate) in (2022) -- We invoiced them in 2022
) as stayed1Y on origin.subscriptionid = stayed1Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2021 -- They started in 2021
        and year(s.invoicedate) in (2023) -- We invoiced them in 2023
) as stayed2Y on origin.subscriptionid = stayed2Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2021 -- They started in 2021
        and year(s.invoicedate) in (2024) -- We invoiced them in 2024
) as stayed3Y on origin.subscriptionid = stayed3Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2021 -- They started in 2021
        and year(s.invoicedate) in (2025) -- We invoiced them in 2025
) as stayed4Y on origin.subscriptionid = stayed4Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2021 -- They started in 2021
        and year(s.invoicedate) in (2026) -- We invoiced them in 2026
) as stayed5Y on origin.subscriptionid = stayed5Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2021 -- They started in 2021
        and year(s.invoicedate) in (2027) -- We invoiced them in 2027
) as stayed6Y on origin.subscriptionid = stayed6Y.subscriptionid
);
create temporary table ag2022 (
   select 
	  2022 as Year,
      5500000.00 as Spend,
      19148 as SubsOrigin, -- Year 2022
      14701100 as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, -- Year 2023
      sum(stayed1Y.contractValue) as CVAfterY1,
      count(stayed2Y.subscriptionID) as SubsAfterY2, -- Year 2024
      sum(stayed2Y.contractValue) as CVAfterY2,
      count(stayed3Y.subscriptionID) as SubsAfterY3, -- Year 2025
      sum(stayed3Y.contractValue) as CVAfterY3,
      if(count(stayed4Y.subscriptionID) = count(stayed3Y.subscriptionID), 0, count(stayed4Y.subscriptionID)) as SubsAfterY4, -- Year 2026
      if(sum(stayed4Y.contractValue) = sum(stayed3Y.contractValue), 0, sum(stayed4Y.contractValue)) as CVAfterY4,
      if(count(stayed5Y.subscriptionID) = count(stayed4Y.subscriptionID), 0, count(stayed5Y.subscriptionID)) as SubsAfterY5, -- Year 2027
      if(sum(stayed5Y.contractValue) = sum(stayed4Y.contractValue), 0, sum(stayed5Y.contractValue)) as CVAfterY5,
      if(count(stayed6Y.subscriptionID) = count(stayed5Y.subscriptionID), 0, count(stayed6Y.subscriptionID)) as SubsAfterY6, -- Year 2028
      if(sum(stayed6Y.contractValue) = sum(stayed5Y.contractValue), 0, sum(stayed6Y.contractValue)) as CVAfterY6
from (
	select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2022 -- They started in 2022
        and year(s.invoicedate) in (2022) -- We invoiced them in 2022
) as origin 
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2022 -- They started in 2022
        and year(s.invoicedate) in (2023) -- We invoiced them in 2023
) as stayed1Y on origin.subscriptionid = stayed1Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2022 -- They started in 2022
        and year(s.invoicedate) in (2024) -- We invoiced them in 2024
) as stayed2Y on origin.subscriptionid = stayed2Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2022 -- They started in 2022
        and year(s.invoicedate) in (2025) -- We invoiced them in 2025
) as stayed3Y on origin.subscriptionid = stayed3Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2022 -- They started in 2022
        and year(s.invoicedate) in (2026) -- We invoiced them in 2026
) as stayed4Y on origin.subscriptionid = stayed4Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2022 -- They started in 2022
        and year(s.invoicedate) in (2027) -- We invoiced them in 2027
) as stayed5Y on origin.subscriptionid = stayed5Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2022 -- They started in 2022
        and year(s.invoicedate) in (2028) -- We invoiced them in 2028
) as stayed6Y on origin.subscriptionid = stayed6Y.subscriptionid
);
create temporary table ag2023 (
   select 
	  2023 as Year,
      5435658 as Spend, -- could also be 5548772.57
      21578 as SubsOrigin, -- Year 2023
      16765883 as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, -- Year 2024
      sum(stayed1Y.contractValue) as CVAfterY1,
      count(stayed2Y.subscriptionID) as SubsAfterY2, -- Year 2025
      sum(stayed2Y.contractValue) as CVAfterY2,
      if(count(stayed3Y.subscriptionID) = count(stayed2Y.subscriptionID), 0, count(stayed3Y.subscriptionID)) as SubsAfterY3, -- Year 2026
      if(sum(stayed3Y.contractValue) = sum(stayed2Y.contractValue), 0, sum(stayed3Y.contractValue)) as CVAfterY3,
      if(count(stayed4Y.subscriptionID) = count(stayed3Y.subscriptionID), 0, count(stayed4Y.subscriptionID)) as SubsAfterY4, -- Year 2027
      if(sum(stayed4Y.contractValue) = sum(stayed3Y.contractValue), 0, sum(stayed4Y.contractValue)) as CVAfterY4,
      if(count(stayed5Y.subscriptionID) = count(stayed4Y.subscriptionID), 0, count(stayed5Y.subscriptionID)) as SubsAfterY5, -- Year 2028
      if(sum(stayed5Y.contractValue) = sum(stayed4Y.contractValue), 0, sum(stayed5Y.contractValue)) as CVAfterY5,
      if(count(stayed6Y.subscriptionID) = count(stayed5Y.subscriptionID), 0, count(stayed6Y.subscriptionID)) as SubsAfterY6, -- Year 2029
      if(sum(stayed6Y.contractValue) = sum(stayed5Y.contractValue), 0, sum(stayed6Y.contractValue)) as CVAfterY6
from (
	select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2023 -- They started in 2023
        and year(s.invoicedate) in (2023) -- We invoiced them in 2023
) as origin 
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2023 -- They started in 2023
        and year(s.invoicedate) in (2024) -- We invoiced them in 2024
) as stayed1Y on origin.subscriptionid = stayed1Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2023 -- They started in 2023
        and year(s.invoicedate) in (2025) -- We invoiced them in 2025
) as stayed2Y on origin.subscriptionid = stayed2Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2023 -- They started in 2023
        and year(s.invoicedate) in (2026) -- We invoiced them in 2026
) as stayed3Y on origin.subscriptionid = stayed3Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2023 -- They started in 2023
        and year(s.invoicedate) in (2027) -- We invoiced them in 2027
) as stayed4Y on origin.subscriptionid = stayed4Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2023 -- They started in 2023
        and year(s.invoicedate) in (2028) -- We invoiced them in 2028
) as stayed5Y on origin.subscriptionid = stayed5Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2023 -- They started in 2023
        and year(s.invoicedate) in (2029) -- We invoiced them in 2029
) as stayed6Y on origin.subscriptionid = stayed6Y.subscriptionid
);
create temporary table ag2024 (
   select 
	  2024 as Year,
      5180626 as Spend,
      24301 as SubsOrigin, -- Year 2024
      19829605 as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, -- Year 2025
      sum(stayed1Y.contractValue) as CVAfterY1,
      if(count(stayed1Y.subscriptionID) = count(origin.subscriptionID), 0, count(stayed1Y.subscriptionID)) as SubsAfterY2, -- Year 2026
      if(sum(stayed1Y.contractValue) = sum(origin.contractValue), 0, sum(stayed1Y.contractValue)) as CVAfterY2,
      if(count(stayed3Y.subscriptionID) = count(stayed2Y.subscriptionID), 0, count(stayed3Y.subscriptionID)) as SubsAfterY3, -- Year 2027
      if(sum(stayed3Y.contractValue) = sum(stayed2Y.contractValue), 0, sum(stayed3Y.contractValue)) as CVAfterY3,
      if(count(stayed4Y.subscriptionID) = count(stayed3Y.subscriptionID), 0, count(stayed4Y.subscriptionID)) as SubsAfterY4, -- Year 2028
      if(sum(stayed4Y.contractValue) = sum(stayed3Y.contractValue), 0, sum(stayed4Y.contractValue)) as CVAfterY4,
      if(count(stayed5Y.subscriptionID) = count(stayed4Y.subscriptionID), 0, count(stayed5Y.subscriptionID)) as SubsAfterY5, -- Year 2029
      if(sum(stayed5Y.contractValue) = sum(stayed4Y.contractValue), 0, sum(stayed5Y.contractValue)) as CVAfterY5,
      if(count(stayed6Y.subscriptionID) = count(stayed5Y.subscriptionID), 0, count(stayed6Y.subscriptionID)) as SubsAfterY6, -- Year 2030
      if(sum(stayed6Y.contractValue) = sum(stayed5Y.contractValue), 0, sum(stayed6Y.contractValue)) as CVAfterY6
from (
	select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2024 -- They started in 2024
        and year(s.invoicedate) in (2024) -- We invoiced them in 2024
) as origin 
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2024 -- They started in 2024
        and year(s.invoicedate) in (2025) -- We invoiced them in 2025
) as stayed1Y on origin.subscriptionid = stayed1Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2024 -- They started in 2024
        and year(s.invoicedate) in (2026) -- We invoiced them in 2026
) as stayed2Y on origin.subscriptionid = stayed2Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2024 -- They started in 2024
        and year(s.invoicedate) in (2027) -- We invoiced them in 2027
) as stayed3Y on origin.subscriptionid = stayed3Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2024 -- They started in 2024
        and year(s.invoicedate) in (2028) -- We invoiced them in 2028
) as stayed4Y on origin.subscriptionid = stayed4Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2024 -- They started in 2024
        and year(s.invoicedate) in (2029) -- We invoiced them in 2029
) as stayed5Y on origin.subscriptionid = stayed5Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2024 -- They started in 2024
        and year(s.invoicedate) in (2030) -- We invoiced them in 2030
) as stayed6Y on origin.subscriptionid = stayed6Y.subscriptionid
);
create temporary table ag2025 (
   select 
	  2025 as Year,
      5180626 as Spend,
      count(origin.subscriptionID) as SubsOrigin, -- Year 2025
      sum(origin.contractValue) as CVOrigin,
      if(count(stayed1Y.subscriptionID) = count(origin.subscriptionID), 0, count(stayed1Y.subscriptionID)) as SubsAfterY1, -- Year 2026
      if(sum(stayed1Y.contractValue) = sum(origin.contractValue), 0, sum(stayed1Y.contractValue)) as CVAfterY1,
      if(count(stayed2Y.subscriptionID) = count(stayed1Y.subscriptionID), 0, count(stayed2Y.subscriptionID)) as SubsAfterY2, -- Year 2027
      if(sum(stayed2Y.contractValue) = sum(stayed1Y.contractValue), 0, sum(stayed2Y.contractValue)) as CVAfterY2,
      if(count(stayed3Y.subscriptionID) = count(stayed2Y.subscriptionID), 0, count(stayed3Y.subscriptionID)) as SubsAfterY3, -- Year 2028
      if(sum(stayed3Y.contractValue) = sum(stayed2Y.contractValue), 0, sum(stayed3Y.contractValue)) as CVAfterY3,
      if(count(stayed4Y.subscriptionID) = count(stayed3Y.subscriptionID), 0, count(stayed4Y.subscriptionID)) as SubsAfterY4, -- Year 2029
      if(sum(stayed4Y.contractValue) = sum(stayed3Y.contractValue), 0, sum(stayed4Y.contractValue)) as CVAfterY4,
      if(count(stayed5Y.subscriptionID) = count(stayed4Y.subscriptionID), 0, count(stayed5Y.subscriptionID)) as SubsAfterY5, -- Year 2030
      if(sum(stayed5Y.contractValue) = sum(stayed4Y.contractValue), 0, sum(stayed5Y.contractValue)) as CVAfterY5,
      if(count(stayed6Y.subscriptionID) = count(stayed5Y.subscriptionID), 0, count(stayed6Y.subscriptionID)) as SubsAfterY6, -- Year 2031
      if(sum(stayed6Y.contractValue) = sum(stayed5Y.contractValue), 0, sum(stayed6Y.contractValue)) as CVAfterY6
from (
	select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2025 -- They started in 2025
        and year(s.invoicedate) in (2025) -- We invoiced them in 2025
) as origin 
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2025 -- They started in 2025
        and year(s.invoicedate) in (2026) -- We invoiced them in 2026
) as stayed1Y on origin.subscriptionid = stayed1Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2025 -- They started in 2025
        and year(s.invoicedate) in (2027) -- We invoiced them in 2027
) as stayed2Y on origin.subscriptionid = stayed2Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2025 -- They started in 2025
        and year(s.invoicedate) in (2028) -- We invoiced them in 2028
) as stayed3Y on origin.subscriptionid = stayed3Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2025 -- They started in 2025
        and year(s.invoicedate) in (2029) -- We invoiced them in 2029
) as stayed4Y on origin.subscriptionid = stayed4Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2025 -- They started in 2025
        and year(s.invoicedate) in (2030) -- We invoiced them in 2030
) as stayed5Y on origin.subscriptionid = stayed5Y.subscriptionid
left join (
select s.subscriptionID, s.dateAdded, s.dateCancelled, s.subtotal + s.creditamount as contractvalue
    from everything as s
    where year(s.dateadded) = 2025 -- They started in 2025
        and year(s.invoicedate) in (2031) -- We invoiced them in 2031
) as stayed6Y on origin.subscriptionid = stayed6Y.subscriptionid
);
create temporary table unity (
   select * 
   from ag2019
   union select * from ag2019
   union select * from ag2020
   union select * from ag2021
   union select * from ag2022
   union select * from ag2023
   union select * from ag2024
   union select * from ag2025
);

#/* This is a select statement that tests the unity connection
select
-- Items from "unity"
Year, Spend, SubsOrigin, CVOrigin, SubsAfterY1, CVAfterY1, SubsAfterY2, CVAfterY2, SubsAfterY3, CVAfterY3, SubsAfterY4, CVAfterY4, SubsAfterY5, CVAfterY5, SubsAfterY6, CVAfterY6,

-- Total Gain calculations
CVOrigin + CVAfterY1 + CVAfterY2 + CVAfterY3 + CVAfterY4 + CVAfterY5 + CVAfterY6 as TotalEarned,
CVAfterY1 + CVAfterY2 + CVAfterY3 + CVAfterY4 + CVAfterY5 + CVAfterY6 as EarnedAFTEROrigin

from unity
order by Year asc;
#*/

/* This is a select statement that tests the calls/subscriptions connection
select *
from filteredsubs;
#*/

/* This is a direct statement for all records
select *
from everything
;*/

/* This is a select statement that tests the connection between tickets and subscriptions
# This query is designed for finding line-by-line accounts AND for aggregates, which is why subscriptionid and addeddate are both selected in this statement
# 'Concat' and 'format' are being used for readability because it's hard to read numbers in the millions
select 
    concat('$', format(sum(subtotal) + sum(creditamount), 2)) as paid, 
    concat('$', format(r.spend, 2)) as spend,
    year(invoicedate) as year
from everything as t
left join roi as r on r.year = year(t.invoicedate)
where year(invoicedate) is not null and year(invoiceDate) >= 2019 # This cleans up the results
group by year(invoicedate);
#*/

/* This is a select statement that tests the connection between tickets and subscriptions
# This query is designed for finding line-by-line accounts
# 'Concat' and 'format' are being used for readability because it's hard to read numbers in the millions
select 
	subscriptionid, 
    addeddate,
    year(addeddate),
    concat('$', format(subtotal + creditamount, 2)) as paid, 
    concat('$', format(r.spend, 2)) as spend,
    year(invoicedate) as year    
from everything as t
left join roi as r on r.year = year(t.invoicedate)
where year(invoicedate) is not null and year(invoiceDate) >= 2019 # This cleans up the results
group by year(invoicedate);
#*/