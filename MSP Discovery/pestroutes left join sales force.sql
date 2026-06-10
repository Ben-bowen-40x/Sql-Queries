#Connect Pestroutes where there is a subscription to billable and non-billable SF data
SELECT 
#s.subscriptionID, m.pestRoutesSubscriptionID, s.customerID, s.dateAdded, s.contractValue, m.qualifiedLeadStage
count(s.subscriptionid), count(qualifiedleadid),
sum(contractValue),
count(ctmID), count(leadid)
FROM dwh_reportsdb.subscription as s
left join dwh_salesforce.MarketingSalesforceLeads as m on m.pestRoutesSubscriptionID = s.subscriptionID
where year(dateAdded) = 2024 and month(dateAdded) = 10 
and pestRoutesSubscriptionID is not null
#and ctmid is not null
;

#Leads
select count(leadid) 
from dwh_salesforce.MarketingSalesforceLeads
where year(createdDate) = 2024 and month(createdDate) = 10
and qualifiedLeadId is not null #If qualifiedLeadID is not null, then include records that became a subscription
and ctmid is not null #If ctmid is not null, then include records that are from IM
;

#For leads
select count(leadid)
from dwh_salesforce.MarketingSalesforceLeads
where year(createdDate) = 2024 and month(createdDate) = 10;

# left joining with 
with salesforce as (
select ctmid, pestroutessubscriptionid, qualifiedleadid, cell
from dwh_salesforce.MarketingSalesforceLeads
where year(createdDate) = 2024 and month(createdDate) = 9
)
select 
c.customerid, f.pestroutessubscriptionid, s.subscriptionid, f.cell, coalesce(c.phone1, c.phone2) as customerphone, s.contractvalue
#sum(s.contractvalue)
from salesforce as f
left join dwh_reportsdb.customer as c on coalesce(c.phone1,c.phone2) = f.cell
left join dwh_reportsdb.subscription as s on s.customerid = c.customerid
where year(s.dateadded) = 2024 and month(s.dateadded) = 9 and pestroutessubscriptionid is not null and s.initialStatus = 1
;
#group by s.subscriptionid

#connections to ctm
with ctm as (
select contact_number_clean
from dwh_ctmdb.calls
where year(datecontacted) = 2024 and month(datecontacted) = 9
and sale_billable = "billable"
)
select #cell, contact_number_clean #, 
count(if(contact_number_clean is null, 1, 0)), count(if(contact_number_clean is null, 0, 1))
from ctm as c
left join dwh_salesforce.MarketingSalesforceLeads as f on f.cell = c.contact_number_clean
where year(f.createddate) = 2024 and month(f.createddate) = 9
;
