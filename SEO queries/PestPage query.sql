SELECT *, p.accountID = 45370514 as National, p.accountID = 326599935 as NationalGA4,
CASE
   when p.pagePath like '%albany-ny%' then 'Albany'
   when p.pagePath like '%baltimore-md%' then 'Baltimore'
   when p.pagePath like '%baton-rouge-la%' then 'Baton Rouge'
   when p.pagePath like '%bloomington%' then 'Bloomington'
   when p.pagePath like '%boston%' then 'Boston'
   when p.pagePath like '%buffalo%' then 'Buffalo'
   when p.pagePath like '%chicago%' then 'Chicago'
   when p.pagePath like '%connecticut%' then 'Connecticut'
   when p.pagePath like '%corpus%' then 'Corpus Christi'
   when p.pagePath like '%dallas%' then 'Dallas Fort Worth'
   when p.pagePath like '%eastern%' then 'Eastern MA'
   when p.pagePath like '%harrisburg%' then 'Harrisburg'
   when p.pagePath like '%hudson%' then 'Hudson Valley'
   when p.pagePath like '%jersey%' then 'New Jersey'
   when p.pagePath like '%lafayette%' then 'Lafayette'
   when p.pagePath like '%lancaster%' then 'Lancaster'
   when p.pagePath like '%lexington%' then 'Lexington'
   when p.pagePath like '%long-island%' then 'Long Island'
   when p.pagePath like '%lubbock%' then 'Lubbock'
   when p.pagePath like '%manchester%' then 'Manchester'
   when p.pagePath like '%mcallen%' then 'McAllen'
   when p.pagePath like '%midland%' then 'Midland'
   when p.pagePath like '%northern%' then 'Northern VA'
   when p.pagePath like '%orlando%' then 'Orlando'
   when p.pagePath like '%pittsburgh%' then 'Pittsburgh'
   when p.pagePath like '%rhode%' then 'Rhode Island'
   when p.pagePath like '%rochester%' then 'Rochester'
   when p.pagePath like '%syracuse%' then 'Syracuse'
   when p.pagePath like '%virginia-beach%'  then 'Virginia Beach'
   Else 'National'
   End as 'Branch'
FROM dwh_googleanalyticsdb.page as p
WHERE (accountID = 45370514 or accountID = 326599935)
and date like '%2023%'
and (
   pagePath like '%/ants/' or
   pagePath like '%/bed-bugs/' or
   pagePath like '%/bees/' or
   pagePath like '%/beetles/' or
   pagePath like '%/boxelder-bugs/' or
   pagePath like '%/carpenter-ants/' or
   pagePath like '%/carpenter-bees/' or
   pagePath like '%/centipedes/' or
   pagePath like '%/cockroaches/' or
   pagePath like '%/crickets/' or
   pagePath like '%/earwigs/' or
   pagePath like '%/fleas/' or
   pagePath like '%/hornets/' or
   pagePath like '%/ladybugs/' or
   pagePath like '%/mice/' or
   pagePath like '%/millipedes/' or
   pagePath like '%/mosquitoes/' or
   pagePath like '%/rats/' or
   pagePath like '%/rodents/' or
   pagePath like '%/scorpions/' or
   pagePath like '%/silverfish/' or
   pagePath like '%/spiders/' or
   pagePath like '%/stink-bugs/' or
   pagePath like '%/ticks/' or
   pagePath like '%/wasps/' or
   pagePath like '%/yellow-jackets/'
 )
 and(
   pagePath like '%albany-ny%' or
   pagePath like '%baltimore-md%' or
   pagePath like '%baton-rouge-la%' or
   pagePath like '%bloomington%' or
   pagePath like '%boston%' or
   pagePath like '%buffalo%' or
   pagePath like '%chicago%' or
   pagePath like '%connecticut%' or
   pagePath like '%corpus%' or
   pagePath like '%dallas%' or
   pagePath like '%eastern%' or
   pagePath like '%harrisburg%' or
   pagePath like '%hudson%' or
   pagePath like '%jersey%' or
   pagePath like '%lafayette%' or
   pagePath like '%lancaster%' or
   pagePath like '%lexington%' or
   pagePath like '%long-island%' or
   pagePath like '%lubbock%' or
   pagePath like '%manchester%' or
   pagePath like '%mcallen%' or
   pagePath like '%midland%' or
   pagePath like '%northern%' or
   pagePath like '%orlando%' or
   pagePath like '%pittsburgh%' or
   pagePath like '%rhode%' or
   pagePath like '%rochester%' or
   pagePath like '%syracuse%' or
   pagePath like '%virginia-beach%'  
 )
 group by 
   pagePath
order by
   pagePath asc