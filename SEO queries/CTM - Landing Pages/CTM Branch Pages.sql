select location as landingPage, count(call_id) as calls, dateContacted, source, sale_billable,

# Page Type filter
case
   when location like '%service-area%' then 'service-area'
end as pageFilter,

# Branch Filter
case 
   when location like '%albany%' 
   or location like '%baltimore%' 
   or location like '%baton-rouge%'
   or location like '%bloomington%' 
   or location like '%boston%' 
   or location like '%buffalo%' 
   or location like '%central-nj%' or location like '%jersey%' 
   or location like '%chicago%' 
   or location like '%corpus-christi%'
   or location like '%connecticut%' 
   or location like '%dallas-fort-worth%' 
   or location like '%bristol-county-ma%' 
   or location like '%harrisburg%' 
   or location like '%hudson-valley-ny%' 
   or location like '%lafayette%' 
   or location like '%lancaster%' 
   or location like '%lexington%' 
   or location like '%long-island%' 
   or location like '%lubbock%' 
   or location like '%manchester%' 
   or location like '%mcallen%' 
   or location like '%midland%' 
   or location like '%covington-la%'
   or location like '%northern-va%' 
   or location like '%orlando-fl%' 
   or location like '%pittsburgh%' 
   or location like '%rhode-island%' 
   or location like '%rochester%' 
   or location like '%syracuse%' 
   or location like '%virginia-beach%' then 'Branch'
   when location like '%local-location%' then 'Generic Location'
   when location = '' or location is null then 'No Page'
   else 'National Pages'
end as branchFilter

from dwh_ctmdb.calls
where year(dateContacted) >= 2021
group by location, source, dateContacted, sale_billable
