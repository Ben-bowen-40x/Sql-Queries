-- Leaferno query validation

select *
from dwh_leadferno.message
where threadid = "ccfd0e11-c679-4d1e-90c5-7aeacf788000"
;

-- Find the threadid of a particular message
select *
from dwh_leadferno.leadferno_messages
#where prospectid in ("5e0db01f-a207-4781-9fba-ac0c8534581d")
-- /*
where messageid in (
"3346cf62-861d-4267-a099-1bd5e0ea8a1f",
"ccbdabaa-724f-4156-8926-6fc328de08d1",
"e486d344-acb3-401c-a2db-292149413fdb"
);#*/

select source from dwh_ctmdb.calls
where year(datecontacted) >= 2023
group by source;

select extract(year from datecontacted), 
case 
	when source in ('GMB','Website','Google Organic','Google My Business','Email','Direct',
    'Yelp','GMB -  Glen Ellyn, IL 60137','Facebook','DuckDuckGo','Referral','Glue Traps','Flea Infographic',
    'BBB','LeadPanel','GMB - Newport News','GMB - Brownsville','Instagram','Blog','Email (HPP Customers)','Commercial Website',
    'Google Business Profile - Static Number','Google Business Profile - Website Visitor'
    ) then 'Not Paid'
    when source not in ('GMB','Website','Google Organic','Google My Business','Email','Direct',
    'Yelp','GMB -  Glen Ellyn, IL 60137','Facebook','DuckDuckGo','Referral','Glue Traps','Flea Infographic',
    'BBB','LeadPanel','GMB - Newport News','GMB - Brownsville','Instagram','Blog','Email (HPP Customers)','Commercial Website',
    'Google Business Profile - Static Number','Google Business Profile - Website Visitor'
    ) then 'Paid'
    else source
    end as `sourcing`, min(datecontacted), source
from dwh_ctmdb.calls
where year(datecontacted) >= '2023' -- and `sourcing` = 'Paid'
group by source
order by extract(year from datecontacted) asc