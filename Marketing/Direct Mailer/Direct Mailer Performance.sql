-- Creative marketing project, Direct mailer
# Phase 1: Total Call Volume, Total Contract Value, Total Home Inspections, Average time to close (call date vs first service date, I guess?)
# Phase 2: Call volume by date compared to campaign launch, Total Home Inspection and Revenue performance by zip, Total home inspection and revenue performance by branch, answer rate, follow ups, call volume by time of day

use dwh_ctmdb;
with sourcedCalls as (
select 
	c.call_id, c.contact_number_clean, c.sale_billable, c.source, date_sub(c.called_at_denver, interval 1 hour) as called_at, 
	dense_rank() over (partition by c.contact_number_clean order by c.called_at asc) as ranking, c.audio, regexp_replace(s.summary, '\n|,','| ') as summary
from dwh_ctmdb.calls as c
left join dwh_ctmdb.call_summary as s on s.call_id = c.call_id
where tracking_number in (
	'+18668454507' -- Field Sales - Direct Mailer
)
), sales as (
select sf.ctmid, sf.pestRoutesSubscriptionID, 
	s.subscriptionid, s.contractvalue
from dwh_salesforce.MarketingSalesforceLeads as sf
left join dwh_reportsdb.subscription as s on s.subscriptionid = sf.pestRoutesSubscriptionID
where ctmid is not null
), app as (
select 
	subscriptionid, date, dense_rank() over (partition by subscriptionid order by date) as appRank
    from dwh_reportsdb.appointment
)

-- /*Direct phone connection without a WITH statement for subscriptions
#Good Draft
select -- apprank, -- appointment data
	ranking, dense_rank() over (partition by a.call_id order by s.dateadded) as callRank, a.call_id, a.contact_number_clean, a.called_at, a.source,
    audio, a.summary,
	s.subscriptionid, c.customerid, s.contractvalue, s.dateAdded as subdate, c.dateAdded as custDate, s.initialstatus,
    case # Sale
		when s.dateadded is null and c.dateadded is null then false
        when s.dateadded is null and c.dateadded is not null and a.called_at < c.dateadded and s.initialStatus = 1 then true
        when s.dateadded is not null and c.dateadded is null and a.called_at < s.dateadded and s.initialStatus = 1 then true
        when s.dateadded is not null and c.dateadded is not null and c.dateadded <= s.dateadded and a.called_at < c.dateadded and s.initialStatus = 1 then true
        when s.dateadded is not null and c.dateadded is not null and c.dateadded >= s.dateadded and a.called_at < s.dateadded and s.initialStatus = 1 then true
        when s.dateadded is not null and a.called_at < s.dateadded and s.initialStatus = 1 then true
        else false
	end as 'Sale',
    case # Current customer
		when s.dateadded is null and c.dateadded is null then false
        when s.dateadded is null and c.dateadded is not null and a.called_at > c.dateadded then true
        when s.dateadded is not null and c.dateadded is null and a.called_at > s.dateadded then true
        when s.dateadded is not null and c.dateadded is not null and c.dateadded <= s.dateadded and a.called_at > c.dateadded then true
        when s.dateadded is not null and c.dateadded is not null and c.dateadded >= s.dateadded and a.called_at > s.dateadded then true
        else false
        end as 'Current Customer',
	case # Time to sell
		when s.dateadded is null and c.dateadded is null then null
        when s.dateadded is null and c.dateadded is not null and a.called_at < c.dateadded then timestampdiff(minute,called_at,c.dateadded)
        when s.dateadded is not null and c.dateadded is null and a.called_at < s.dateadded then timestampdiff(minute,called_at,s.dateadded)
        when s.dateadded is not null and c.dateadded is not null and c.dateadded <= s.dateadded and a.called_at < c.dateadded then timestampdiff(minute,called_at, c.dateadded)
        when s.dateadded is not null and c.dateadded is not null and c.dateadded >= s.dateadded and a.called_at < s.dateadded then timestampdiff(minute,called_at, c.dateadded)
        else null
	end as 'Time to sell (minutes)',
    /* Time to service, using appointment
    case # Time to service
		when app.date is null then null
        when app.date < a.called_at then null
        when a.called_at < app.date then timestampdiff(minute, called_at, app.date)
        else null
	end as 'Time to service (minutes)', #*/
    case # Sale Value
		when s.dateadded is null and c.dateadded is null then 0
        when s.dateadded is null and c.dateadded is not null and a.called_at < c.dateadded then s.contractvalue
        when s.dateadded is not null and c.dateadded is null and a.called_at < s.dateadded then s.contractValue
        when s.dateadded is not null and c.dateadded is not null and c.dateadded <= s.dateadded and a.called_at < c.dateadded then s.contractValue
        when s.dateadded is not null and c.dateadded is not null and c.dateadded >= s.dateadded and a.called_at < s.dateadded then s.contractValue
        when s.dateadded is not null and a.called_at < s.dateadded then s.contractvalue
        else 0
	end as 'Sale Value',
    s.serviceType, c.zip
from sourcedCalls as a
left join dwh_reportsdb.customer as c on coalesce(phone1, phone2) = a.contact_number_clean
left join dwh_reportsdb.subscription as s on c.customerid = s.customerid
/* Add appointment data
left join #dwh_reportsdb.appointment 
	(select *
	from app
	where apprank = 1)
as app on app.subscriptionID = s.subscriptionid #*/
where ranking = 1
-- group by call_id
order by called_at desc
;#*/
