Select 
	Month(s.dbDate) as Month, 
	#year(s.dbDate) as Year,
case
	when s.customerID = "4313995931" then "Albany"
   when s.customerID = "8588818494" then "Baton Rouge"
   when s.customerID = "7713864811" then "Bloomington"
   when s.customerID = "9109993096" then "Boston"
   when s.customerID = "5562236429" then "Buffalo"
   when s.customerID = "8642341252" then "Central NJ"
   when s.customerID = "6061812199" then "Chicago"
   when s.customerID = "4287759362" then "Corpus Christi"
   when s.customerID = "3153837978" then "CT"
   when s.customerID = "5844274480" then "Dallas Fort Worth"
   when s.customerID = "2557223813" then "Harrisburg"
   when s.customerID = "8438334847" then "Hudson Valley"
   when s.customerID = "9634801997" then "Lafayette"
   when s.customerID = "2499442546" then "Lexington"
   when s.customerID = "4884600407" then "Long Island"
   when s.customerID = "5659245441" then "Lubbock"
   when s.customerID = "1092125678" then "Manchester"
   when s.customerID = "3916019625" then "McAllen"
   when s.customerID = "2594010705" then "Midland"
   when s.customerID = "8138373690" then "North Shore"
   when s.customerID = "8242438560" then "Northern VA"
   when s.customerID = "3557581058" then "Orlando"
   when s.customerID = "6146213948" then "Pittsburgh"
   when s.customerID = "3954672296" then "Rhode Island"
   when s.customerID = "2043109899" then "Rochester"
   when s.customerID = "7263307645" then "Syracuse"
   when s.customerID = "1567026297" then "Virginia Beach"
else "Google Ads" end as Branch,
   Round(sum(s.cost), 2) as Spend,
   l.leads

from dwh_googleadsdb.campaign_stats as s
left join dwh_googleadsdb.campaign_def as d on s.customerID = d.customerID #campaign_def has office id, but campaign_stats does no
left join 
(
   Select 
   
   Count(if(c.sale_billable="billable" and c.source like "%LSA%", true, false)) as Leads
   from dwh_ctmdb.calls as c
   where year(c.called_at) = "2023" and month(c.called_at) = "09"
) as l on d.officeID = l.officeID
WHERE year(s.dbDate) = "2023" and month(s.dbDate) = "09"
	and s.customerID != '6850114974' #eliminate Google Ads from results*/
group by 
	Branch
Order by
	Branch asc