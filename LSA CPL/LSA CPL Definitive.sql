with 
/*Create temporary table */ LSA_Spend
as(
Select 
	d.officeID,
	year(s.dbDate) as Year,
	Month(s.dbDate) as Month,
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
   Round(sum(s.cost), 2) as Spend
from dwh_googleadsdb.campaign_stats as s
left join dwh_googleadsdb.campaign_def as d on s.customerID = d.customerID #campaign_def has office id, but campaign_stats does not
WHERE year(s.dbDate)=2023 and month(s.dbDate)=08
	and s.customerID != '6850114974' #eliminate Google Ads from results*/
group by d.customerID
Order by d.officeID asc
),
#;

/*Create temporary table */LSA_Billable
as (
Select o.branchName, #c.called_at,
case
	when c.officeID is null then 0
	when c.officeID=1 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=2 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=3 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=4 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=5 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=6 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=7 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=8 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=9 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=10 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=11 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=12 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=13 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=14 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=15 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=16 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=17 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=18 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=19 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=20 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=21 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=22 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=23 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=24 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=25 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=26 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=27 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=28 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=29 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=30 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=31 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) 
	when c.officeID=32 then sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0))
	else sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0))
end as Leads,
case 
   when c.officeID=16  then "Albany"
   when c.officeID=4  then "Baton Rouge"
   when c.officeID=22  then "Bloomington"
   when c.officeID=18  or c.officeID=27 then "Boston"
   when c.officeID=5  then "Buffalo"
   when c.officeID=30  then "Central NJ"
   when c.officeID=32 or c.officeID=6  then "Chicago"
   when c.officeID=7  then "Corpus Christi"
   when c.officeID=13  or c.officeID=31 then "CT"
   when c.officeID=25  then "Dallas Fort Worth"
   when c.officeID=20  then "Harrisburg"
   when c.officeID=15  then "Hudson Valley"
   when c.officeID=19  then "Lafayette"
   when c.officeID=8  then "Lexington"
   when c.officeID=9  then "Long Island"
   when c.officeID=10  then "Lubbock"
   when c.officeID=21  then "Manchester"
   when c.officeID=11  then "McAllen"
   when c.officeID=12  then "Midland"
   when c.officeID=23  then "North Shore"
   when c.officeID=26  then "Northern VA"
   when c.officeID=28  then "Orlando"
   when c.officeID=29  then "Pittsburgh"
   when c.officeID=2  then "Rhode Island"
   when c.officeID=14  then "Rochester"
   when c.officeID=17  then "Syracuse"
   when c.officeID=3  then "Virginia Beach"
   when c.officeID=24 then "Newport News"
    else c.officeID
end as "Branch"
from dwh_ctmdb.calls as c
left join dwh_reportsdb.office as o on o.officeID=c.officeID
where year(c.called_at)=2023 and month(c.called_at)=08
group by c.officeID
order by c.officeID asc
)
#;

Select s.Year, s.Month, s.officeID, b.branchName, b.Branch, b.Leads, s.Spend
from LSA_Billable b
left join LSA_Spend s on b.Branch=s.Branch
order by b.branchName asc
;