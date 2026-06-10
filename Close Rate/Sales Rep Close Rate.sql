with answerAg as (
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
	end as `Month Name`,#*/
    a.fullname as `AnsweringRep`,
	s.contractvalue as `Contract Value`,
	e2.fullname as `Seller`, f.pestroutessubscriptionid
    -- /* Aggregates
    , sum(s.contractvalue) as `Earned Value`, 
    count(e2.fullname)/count(a.fullname)*100 as `Close Rate`
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
    and f.ctmid is not null
group by `Year`, `Month`, 
`AnsweringRep`
order by `Month`, `AnsweringRep`
), sellerag as (
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
	end as `Month Name`,#*/
    a.fullname as `AnsweringRep`,
	s.contractvalue as `Contract Value`,
	e2.fullname as `Seller`, f.pestroutessubscriptionid
    -- /*
    , sum(s.contractvalue) as `Earned Value`, 
    count(e2.fullname)/count(a.fullname)*100 as `Close Rate`
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
    and f.ctmid is not null
group by `Year`, `Month`, 
`Seller`
order by `Month`, `AnsweringRep`
), employee as (
select fullname
from dwh_reportsdb.employee
)

select *
from employee as e
left join 
(select * from answerAg as a
union 
select * from sellerag as s) as u on u.`AnsweringRep` = e.fullname
where u.`AnsweringRep` is not null