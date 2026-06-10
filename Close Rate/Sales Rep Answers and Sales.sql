-- /* Associate leads with reps who answered a call
-- Duration: 9.125 / Fetch: 19.172
-- The goal is to find the close rate for each rep
select 
	-- f.leadid as `Opportunity`, f.leadcontactmethod,
    year(timestamp) as `Year`,
    month(timestamp) as `Month`,
    case
		when month(timestamp) = 1 then "January"
        when month(timestamp) = 2 then "February"
        when month(timestamp) = 3 then "March"
        when month(timestamp) = 4 then "April"
        when month(timestamp) = 5 then "May"
        when month(timestamp) = 6 then "June"
        when month(timestamp) = 7 then "July"
        when month(timestamp) = 8 then "August"
        when month(timestamp) = 9 then "September"
        when month(timestamp) = 10 then "October"
        when month(timestamp) = 11 then "November"
        when month(timestamp) = 12 then "December"
        else null
	end as `Month Name`,
    a.fullname as `Answering Rep`,
	s.contractvalue as `Contract Value`,
	e2.fullname as `Seller`, f.pestroutessubscriptionid as `Subscription ID`, f.ctmid
    -- /* Aggregates
    , sum(s.contractvalue) as `Earned Value`
    , count(e2.fullname)/count(a.fullname)*100 as `Close Rate`
    , count(e2.fullname) as `SellerCt`, count(a.fullname) as `AnsweringCt`
		#*/--  Retreives aggregates
from dwh_salesforce.MarketingSalesforceLeads as f -- where date(f.createddate) >= "2025-01-01"
left join dwh_five9db.calls as v 
	on v.callid = f.five9id
left join dwh_five9db.agent as a
	on a.agentID = v.agentid
left join dwh_reportsdb.subscription as s 
	on s.subscriptionID = f.pestroutessubscriptionid
left join dwh_reportsdb.employee as e2 
	on e2.employeeid = s.soldby
where date(f.createddate) >= "2025-01-01"
	-- and qualifiedleadid is not null     # This line assumes an opportunity is a qualifiedlead
    and f.five9id is not null and f.ctmid is not null
group by -- `Year`, `Month`, 
`Answering Rep`
order by 
	-- `Month`, 
    `Answering Rep`
;

-- /*
select contractvalue, soldby, employeeid, fullname, dateadded
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.employee as e on e.employeeID = s.soldBy
where employeeid is not null and dateadded >= '2025-01-01'
group by fullname
;#*/

-- /* Employee table exploration
select *-- , linkedEmployeeIDs=consolidatedemployeeid, max(snapshotDate)-- , count(employeeid), count(consolidatedEmployeeID)
from dwh_reportsdb.employee
where fname like "evan%" and lname like "Webb%"
-- group by consolidatedEmployeeID
group by employeeid
order by lname desc
;

select firstName, fullname, lastname
from dwh_five9db.agent
-- where firstname like "evan%"
;

select soldby, fullname,e.active
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.employee as e on e.employeeid = s.soldby
where soldby in (
95263,44347,69572,44365,44407,44487,44688,44729,44751,44891,44975,45112,45244,45263,45284,45287,
45330,45380,47079,52818,76630,73889,73219,70457,44296,91809,91066,90873,90839,90343,90250,90246,
43356,43545,43769,43776,43812,43895,43937,43945,43947,43989,44129,44286,44340)
group by e.employeeid
;#*/

select snapshotdate
from dwh_reportsdb.employee
order by snapshotDate desc