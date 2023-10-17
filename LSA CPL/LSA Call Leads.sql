Select o.branchName, c.called_at,
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
    else c.officeID
end as "Branch"
from dwh_ctmdb.calls as c
left join dwh_reportsdb.office as o on o.officeID=c.officeID
where year(c.called_at)="2023" and month(c.called_at)="09"
group by c.officeID
order by c.officeID asc;