-- There are multiple approaches to this project
-- /* Leo's query for zip codes
SELECT 
sf.branchname,
sf.createddate,
  sf.zipCode,
  COUNT(sf.qualifiedLeadID) AS Leads,
  COUNT(CASE WHEN sub.initialStatus = 1 THEN 1 END) AS subscribedCustomers,
  SUM(contractvalue) AS totalContractValue,
CAST(COUNT(CASE WHEN sub.initialStatus = 1 THEN 1 END) AS FLOAT) /
CAST(NULLIF(COUNT(sf.qualifiedLeadID), 0) AS FLOAT) AS conversionRatePct, 
COUNT(cancellationReasonID) AS Cancellations,
CAST(COUNT(sub.cancellationReasonID) AS FLOAT) /
  NULLIF(COUNT(CASE WHEN sub.initialStatus = 1 THEN 1 END), 0) AS cancellationRate

FROM dwh_salesforce.MarketingSalesforceLeads sf
LEFT JOIN dwh_reportsdb.subscription sub
  ON sf.pestRoutesSubscriptionID = sub.subscriptionID
WHERE YEAR(sf.createdDate) = 2025
  AND (
    sf.leadContactMethod LIKE '%ctm%' OR 
    sf.leadContactMethod LIKE '%contact form%'
  )
GROUP BY sf.zipCode;
#*/

-- /* Sales force connection
with sales as (
select 
	if(qualifiedleadid is null, "", qualifiedleadid) as qualifiedleadid,
    if(ctmid is null, "", ctmid) as ctmid,
    if(zipcode is null, "", zipcode) as zipcode,
    if(pestroutessubscriptionid is null, "", pestroutessubscriptionid) as pestroutessubscriptionid,
    branchname
from dwh_salesforce.MarketingSalesforceLeads
where createddate >= '2025-01-01'
), ctm as (
select contact_number_clean, datecontacted, call_id, source
from dwh_ctmdb.calls 
where source in ('Ad Extension', 'Discovery Ads', 'Google Ads', 'Google Adwords', 'Google Call Extension')
)
select 
	c.contact_number_clean, c.datecontacted,
    sf.qualifiedleadid, -- count(sf.qualifiedleadid) as leads,	
    s.subscriptionid, -- count(s.subscriptionID) as subs, 
    s.contractvalue, -- sum(s.contractValue) as totalContractValue
    sf.branchname, sf.zipcode
from ctm as c
left join sales as sf on (sf.ctmid = c.call_ID /*or sf.ctmid is null*/)
left join dwh_reportsdb.subscription as s on sf.pestroutessubscriptionid = s.subscriptionid 
where 
	s.initialStatus = 1
	-- and contractvalue is not null and sf.zipcode is not null
-- group by sf.zipcode
;#*/

-- /* salesforce connection v2
with ctm as (
select call_id, contact_number_clean, datecontacted, sale_billable
from dwh_ctmdb.calls 
where sale_billable = "billable"
)

select 
	c.*, 
	sf.qualifiedleadid, -- count(sf.qualifiedleadid) as leads,	
    s.subscriptionid, -- count(s.subscriptionID) as subs, 
    s.contractvalue, -- sum(s.contractValue) as totalContractValue
    sf.branchname, sf.zipcode
;#*/

/* Customer connection
select
	o.branchname,
    concat(" ", m.zip) as zip,
    -- count(if(c.sale_billable="billable", 1,0)) as leads,
    count(s.subscriptionid) as subs,
    sum(s.contractValue) as totalContractValue
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.customer as m on m.customerid = s.customerid
left join dwh_ctmdb.calls as c on coalesce(m.phone1, m.phone2) = c.contact_number_clean
left join dwh_reportsdb.office as o on o.officeid = m.officeid
where 
	c.dateContacted >= '2023-01-01' and s.dateadded >= '2023-01-01'
    #customers with longevity
    -- and datediff(m.datecancelled, m.dateadded) >= 365 and datediff(s.datecancelled, s.dateadded) >= 365
    and s.initialStatus = 1
    -- and c.source in ('Ad Extension', 'Discovery Ads', 'Google Ads', 'Google Adwords', 'Google Call Extension')
    and s.contractValue is not null 
    and m.zip is not null and m.zip > 11111
-- group by m.zip
;#*/

/* This checks the various sources, used for filtering
select source
from dwh_ctmdb.calls 
group by source
;#*/