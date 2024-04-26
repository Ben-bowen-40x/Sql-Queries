with pageTypes as (
   select call_id, if(sale_billable = "billable", 1, 0) as billable, dateContacted,
   case
      when source like "%Google Ad%" then "Google Ads"
      when (location like "%bed-bugs%") or (location like "%ant%") or (location like "%bee%") or (location like "%boxelder-bug%") 
         or (location like "%centipede%") or (location like "%roach%") or (location like "%cricket%") or (location like "%earwig%") or (location like "%earwig%") 
         or (location like "%flea%") or (location like "%hornet%") or (location like "%ladybug") or (location like "%mice%") or (location like "%mouse%") 
         or (location like "%millipede%") or (location like "%mole%") or (location like "%mosquito%") or (location like "%rat%") or (location like "%rodent%") 
         or (location like "%scorpion%") or (location like "%silverfish%") or (location like "%spider%") or (location like "%stink-bug%") or (location like "%tick%") 
         or (location like "%termite%") or (location like "%wasp%") or (location like "%yellow-jacket%") or (location like "%vole%") 
            then "Pest Page"
      when location like '%albany%' or (location like '%baltimore%' ) or (location like '%baton-rouge%') or (location like '%bloomington%') or (location like '%boston%') 
         or (location like '%buffalo%') or (location like '%central-nj%' ) or (location like '%jersey%') or (location like '%chicago%') or (location like '%corpus-christi%') 
         or (location like '%connecticut%') or (location like '%dallas-fort-worth%') or (location like '%bristol-county-ma%') or (location like '%harrisburg%') 
         or (location like '%hudson-valley-ny%') or (location like '%lafayette%') or (location like '%lancaster%') or (location like '%lexington%') or (location like '%long-island%') 
         or (location like '%lubbock%') or (location like '%manchester%') or (location like '%mcallen%') or (location like '%midland%') or (location like '%covington-la%') 
         or (location like '%northern-va%') or (location like '%orlando-fl%') or (location like '%pittsburgh%') or (location like '%rhode-island%') or (location like '%rochester%') 
         or (location like '%syracuse%') or (location like '%virginia-beach%' ) then 'Branch Page'
      when location = "https://fox-pest.com/" 
		   then "Home Page"
      when (location like "%sentricon%") or (location like "%home-protection-plan%") or (location like "%yard-enjoyment-plan%") or (location like "%service-plan%") 
		   then "Service Page"
      else 'Other'
   end as "PageType"
   from dwh_ctmdb.calls
)

select count(call_id) as "Total Calls", sum(billable) as "Billable Calls", PageType as "Page Type"
from pageTypes 
where year(dateContacted) >= 2023
group by PageType