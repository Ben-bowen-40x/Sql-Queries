select location as landingPage, count(call_id) as calls, dateContacted, source, sale_billable,

/*# Sources
case 
	when source like 'GMB%' or source = 'Google My Business' or source like 'GBP' then 'GBP'
    when source = 'Google Ads' or source = 'Google Adwords' or source = 'Google Call Extension' then 'Google Ads'
    when source like 'Facebook%' then 'Facebook'
    when source like 'Influencer%' then 'Influencer'
    when source like 'Mom%' then 'Mom Network'
    when source like 'Bing%' then 'Bing'
    when source = 'HomeAdvisor' or source = 'Home Advisor' then 'Home Advisor'
    when source = 'Local Biz Leads' or source = 'LocalBizCalls' then 'Local Biz'
end as source,

# Social Media utm
case
   when location like '%instagram%' then 'instagram'
   when location like '%facebook%' then 'facebook'
   when location like '%fbclid%' then 'facebook click id'
   when location like '%tiktok%' then 'tiktok'
end as socialMediaFilter,

# Campaigns
case
   when location like '%sketchin-tech%' then 'sketchin tech'
   when location like '%all_zip_codes%' then 'all zip codes'
   when location like '%social%' then 'social'
end as campaignFilter,*/

# Service types
case
   when location like '%sentricon%' then 'Sentricon'
   when location like '%home-protection-plan%' then 'Home Protection Plan'
   when location like '%yard-enjoyment-plan%' then 'Yard Enjoyment Plan'
   when location like '%bed-bug-treatment%' then 'Bed Bug Treatment'
   when location like '%service-plans%' then 'Service Plans'
   when location like '%ant%' and location not like '%carpenter-ant%' then 'Ants'
   when location like '%bed-bug%' then 'Bed Bugs'
   when location like '%bee%' and location not like '%carpenter-bee%' then 'Bees'
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

# Site Filters
case
   when location like '%fox-pest.com%' then 'fox-pest.com'
   when location like '%foxpest%' then 'Old websites'
   else 'Others'
end as siteFilters,

# Branch Filter
case 
   when location like '%albany%' then 'Albany'
   when location like '%baltimore%' then 'Baltimore'
   when location like '%baton-rouge%' then 'Baton Rouge'
   when location like '%bloomington%' then 'Bloomington'
   when location like '%boston%' then 'Boston'
   when location like '%buffalo%' then 'Buffalo'
   when location like '%central-nj%' then 'Central NJ'
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
group by location, source, dateContacted
