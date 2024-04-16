select location as landingPage, count(call_id) as calls, dateContacted, source, sale_billable,

# Paid and nonpaid sources
case
	when lower(source) = 'direct' 
		or lower(source) like '%website%' 
        or lower(source) like '%organic%' 
        or lower(source) like '%gbp%'
        or lower(source) like '%gmb%'
        or lower(source) = 'google my business'
        or lower(source) like '%duck%'
			then 'Non-Paid'
	when lower(source) like '%facebook%'
		or lower(source) like '%yelp%'
        or location like ''
        or location is null
			then 'Non-website'
	else 'Paid'
end as Paid,

# Source Filter
case 
   when source = 'Ad Extension' or source = ''
   'BBB'
   '%Bing%' then 'Bing'
   when source = 'Chamber eblast' or source = 'Consumer Affairs' or source = 'Influencers' or source = 'Moms Network' or source like '%S&B%' then 'Linkbuilding'
   when source like '%Facebook$' then 'Facebook'
   when source like '%GMB%' or source = 'Google My Business' then 'GMB'
   when source like '%Youtube%' then 'Youtube'
   else source
end as sourceFilter,   

# Service types
case
   when location like '%sentricon%' then 'Sentricon'
   when location like '%home-protection-plan%' then 'Home Protection Plan'
   when location like '%yard-enjoyment-plan%' then 'Yard Enjoyment Plan'
   when location like '%bed-bug-treatment%' then 'Bed Bug Treatment'
   when location like '%service-plans%' then 'Service Plans'
   when location like '%ant%' and location not like '%carpenter-ant%' then 'Ants'
   when location like '%bed-bug%' then 'Bed Bugs'
   when location like '%bee%' and location not like '%carpenter-bee%' and location not like '%beetle%' then 'Bees'
   when location like '%beetle%' then 'Beetles'
   when location like '%boxelder-bug%' then 'Boxelder Bugs'
   when location like '%carpenter-ant%' then 'Carpenter Ants'
   when location like '%carpenter-bee%' then 'Carpenter Bees'
   when location like '%centipede%' then 'Centipedes'
   when location like '%cockroach%' then 'Cockroaches'
   when location like '%cricket%' then 'Crickets'
   when location like '%earwig%' then 'Earwigs'
   when location like '%flea%' then 'Fleas'
   when location like '%hornet%' then 'Hornets'
   when location like '%ladybug%' then 'Ladybugs'
   when location like '%mice%' or location like '%mouse%' then 'Mice'
   when location like '%millipede%' then 'Millipedes'
   when location like '%mole%' then 'Moles'
   when location like '%mosquito%' then 'Mosquitoes'
   when location like '%rat%' then 'Rats'
   when location like '%rodent%' then 'Rodents'
   when location like '%scorpion%' then 'Scorpions'
   when location like '%silverfish%' then 'Silverfish'
   when location like '%spider%' then 'Spiders'
   when location like '%stink-bug%' then 'Stink Bugs'
   when location like '%tick%' then 'Ticks'
   when location like '%termite%' then 'Termites'
   when location like '%wasp%' then 'Wasps'
   when location like '%yellow-jacket%' then 'Yellow Jackets'
   when location like '%vole%' then 'Voles'
   when location like '%termite-defense-plan%' then 'Termite Defense Plan'
end as serviceFilter,

# Page Type filter
case
   when location like '%blog%' then 'blog'
   when location like '%service-area%' then 'service-area'
   when location like '%contact-form%' then 'contact-form'
   when location like '%about-us%' then 'about us'
   when location like '%contact-us%' then 'contact us'
end as pageFilter,

# Page filter
case
   when location like '%service-area%' then 'service-area'
      else 'Other'
end as pageType,

# Site Filters
case
   when location like '%fox-pest.com%' then 'fox-pest.com'
   when location like '%foxpest%' then 'Old websites'
   else 'Others'
end as siteFilters,

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
      or location like '%virginia-beach%' 
         then 'Branch'#(lf)   
   when location like '%local-location%' then 'Generic Location'
   when location = '' or location is null then 'No Page'
   else 'National Pages'
   end as branchType,

# Branch Filter
case 
   when location like '%albany%' then 'Albany'
   when location like '%baltimore%' then 'Baltimore'
   when location like '%baton-rouge%' then 'Baton Rouge'
   when location like '%bloomington%' then 'Bloomington'
   when location like '%boston%' then 'Boston'
   when location like '%buffalo%' then 'Buffalo'
   when location like '%central-nj%' or location like '%jersey%' then 'Central NJ'
   when location like '%chicago%' then 'Chicago'
   when location like '%corpus-christi%' then 'Corpus Christi'
   when location like '%connecticut%' then 'Connecticut'
   when location like '%dallas-fort-worth%' then 'Dallas FW'
   when location like '%bristol-county-ma%' then 'Eastern MA'
   when location like '%harrisburg%' then 'Harrisburg'
   when location like '%hudson-valley-ny%' then 'Hudson Valley'
   when location like '%lafayette%' then 'Lafayette'
   when location like '%lancaster%' then 'Lancaster'
   when location like '%lexington%' then 'Lexington'
   when location like '%long-island%' then 'Long Island'
   when location like '%lubbock%' then 'Lubbock'
   when location like '%manchester%' then 'Manchester'
   when location like '%mcallen%' then 'McAllen'
   when location like '%midland%' then 'Midland'
   when location like '%covington-la%' then 'North Shore'
   when location like '%northern-va%' then 'Northern VA'
   when location like '%orlando-fl%' then 'Orlando'
   when location like '%pittsburgh%' then 'Pittsburgh'
   when location like '%rhode-island%' then 'Rhode Island'
   when location like '%rochester%' then 'Rochester'
   when location like '%syracuse%' then 'Syracuse'
   when location like '%virginia-beach%' then 'VA Beach'
   when location like '%local-location%' then 'Generic Location'
   when location = '' or location is null then 'No Page'
   else 'National Pages'
end as branchFilter

from dwh_ctmdb.calls
where year(dateContacted) >= 2021
group by location, source, dateContacted, sale_billable