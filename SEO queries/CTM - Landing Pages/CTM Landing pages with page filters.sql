select location as landingPage, count(call_id) as calls, source, dateContacted,
case 
	# Branch Filter
   when location like "https://fox-pest.com/albany%" then "Albany"
   when location like "https://fox-pest.com/baltimore%" then "Baltimore"
   when location like "https://fox-pest.com/baton-rouge%" then "Baton Rouge"
   when location like "https://fox-pest.com/bloomington%" then "Bloomington"
   when location like "https://fox-pest.com/boston%" then "Boston"
   when location like "https://fox-pest.com/buffalo%" then "Buffalo"
   when location like "https://fox-pest.com/central-nj%" then "Central NJ"
   when location like "https://fox-pest.com/chicago%" then "Chicago"
   when location like "https://fox-pest.com/corpus-christi%" then "Corpus Christi"
   when location like "https://fox-pest.com/connecticut%" then "Connecticut"
   when location like "https://fox-pest.com/dallas-fort-worth%" then "Dallas FW"
   when location like "https://fox-pest.com/bristol-county-ma%" then "Eastern MA"
   when location like "https://fox-pest.com/harrisburg%" then "Harrisburg"
   when location like "https://fox-pest.com/hudson-valley-ny%" then "Hudson Valley"
   when location like "https://fox-pest.com/lafayette%" then "Lafayette"
   when location like "https://fox-pest.com/lancaster%" then "Lancaster"
   when location like "https://fox-pest.com/lexington%" then "Lexington"
   when location like "https://fox-pest.com/long-island%" then "Long Island"
   when location like "https://fox-pest.com/lubbock%" then "Lubbock"
   when location like "https://fox-pest.com/manchester%" then "Manchester"
   when location like "https://fox-pest.com/mcallen%" then "McAllen"
   when location like "https://fox-pest.com/midland%" then "Midland"
   when location like "https://fox-pest.com/covington-la%" then "North Shore"
   when location like "https://fox-pest.com/northern-va%" then "Northern VA"
   when location like "https://fox-pest.com/orlando-fl%" then "Orlando"
   when location like "https://fox-pest.com/pittsburgh%" then "Pittsburgh"
   when location like "https://fox-pest.com/rhode-island%" then "Rhode Island"
   when location like "https://fox-pest.com/rochester%" then "Rochester"
   when location like "https://fox-pest.com/syracuse%" then "Syracuse"
   when location like "https://fox-pest.com/virginia-beach%" then "VA Beach"
   when location like "https://fox-pest.com/local-location%" then "Generic Location"
   # Page Filters
   when location like "%blog%" then "blog"
   when location like "%service-area%" then "service-area"
   when location like "%sketchin-tech%" then "sketchin tech"
end as filter

from dwh_ctmdb.calls
group by location