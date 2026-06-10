-- We're comparing monthly IM sale rate by branch against monthly total company cancellation rates by branch

-- ALL sales
select 
	year(s.dateadded) as `Year`,
    month(s.dateadded) as `MonthNum`,
    case -- full name of the month the sub started
		when month(s.dateadded) = 1 then "January"
        when month(s.dateadded) = 2 then "February"
        when month(s.dateadded) = 3 then "March"
        when month(s.dateadded) = 4 then "April"
        when month(s.dateadded) = 5 then "May"
        when month(s.dateadded) = 6 then "June"
        when month(s.dateadded) = 7 then "July"
        when month(s.dateadded) = 8 then "August"
        when month(s.dateadded) = 9 then "September"
        when month(s.dateadded) = 10 then "October"
        when month(s.dateadded) = 11 then "November"
        when month(s.dateadded) = 12 then "December"
	end as `Month`,
    o.branchName as `Branch Name`,
    count(subscriptionid) as `Sales`, -- Number of sales
    sum(contractvalue) as `Contract Value` -- Contract value
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.office as o on o.officeid = s.officeid
where initialstatus = 1 and dateadded >= '2022-01-01' and dateadded <= now()
group by year(s.dateadded), month(s.dateadded), s.officeid
order by year(s.dateadded) asc, month(dateadded) asc, o.branchname asc
;    

-- Total cancellations
select 
	year(s.datecancelled) as `Year`,
    month(s.datecancelled) as `MonthNum`,
    case -- full name of the month the sub cancelled
		when month(s.datecancelled) = 1 then "January"
        when month(s.datecancelled) = 2 then "February"
        when month(s.datecancelled) = 3 then "March"
        when month(s.datecancelled) = 4 then "April"
        when month(s.datecancelled) = 5 then "May"
        when month(s.datecancelled) = 6 then "June"
        when month(s.datecancelled) = 7 then "July"
        when month(s.datecancelled) = 8 then "August"
        when month(s.datecancelled) = 9 then "September"
        when month(s.datecancelled) = 10 then "October"
        when month(s.datecancelled) = 11 then "November"
        when month(s.datecancelled) = 12 then "December"
	end as `Month`,
    o.branchName as `Branch Name`,
    count(subscriptionid) as `Cancels`, -- Number of cancels
    sum(contractvalue) as `Contract Value` -- Contract value
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.office as o on o.officeid = s.officeid
where initialstatus = 1 and datecancelled >= '2022-01-01' and datecancelled <= now()
group by year(datecancelled), month(datecancelled), s.officeid
order by year(datecancelled) asc, month(datecancelled) asc, o.branchname asc;
;

-- IM sales only
select 
	year(s.dateadded) as `Year`,
    month(s.dateadded) as `MonthNum`,
    case -- full name of the month the sub started
		when month(s.dateadded) = 1 then "January"
        when month(s.dateadded) = 2 then "February"
        when month(s.dateadded) = 3 then "March"
        when month(s.dateadded) = 4 then "April"
        when month(s.dateadded) = 5 then "May"
        when month(s.dateadded) = 6 then "June"
        when month(s.dateadded) = 7 then "July"
        when month(s.dateadded) = 8 then "August"
        when month(s.dateadded) = 9 then "September"
        when month(s.dateadded) = 10 then "October"
        when month(s.dateadded) = 11 then "November"
        when month(s.dateadded) = 12 then "December"
	end as `Month`,
    o.branchName as `Branch Name`,
    count(subscriptionid) as `Sales`, -- Number of sales
    sum(contractvalue) as `Contract Value` -- Contract value
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.office as o on o.officeid = s.officeid
where initialstatus = 1 and dateadded >= '2022-01-01' and dateadded <= now()
	and source in (
    "Thumbtack","Social Media","Marketing Email/Text","Local Service Ad (Google)",
    "Internet- WGL","Internet- Organic","Internet Search","Internet","HomeAdvisor","Google",
    "Dex Digital","Aktify"
    )
group by year(s.dateadded), month(s.dateadded), s.officeid
order by year(s.dateadded) asc, month(dateadded) asc, o.branchname asc
;    

-- IM cancellations only
select 
	year(s.datecancelled) as `Year`,
    month(s.datecancelled) as `MonthNum`,
    case -- full name of the month the sub cancelled
		when month(s.datecancelled) = 1 then "January"
        when month(s.datecancelled) = 2 then "February"
        when month(s.datecancelled) = 3 then "March"
        when month(s.datecancelled) = 4 then "April"
        when month(s.datecancelled) = 5 then "May"
        when month(s.datecancelled) = 6 then "June"
        when month(s.datecancelled) = 7 then "July"
        when month(s.datecancelled) = 8 then "August"
        when month(s.datecancelled) = 9 then "September"
        when month(s.datecancelled) = 10 then "October"
        when month(s.datecancelled) = 11 then "November"
        when month(s.datecancelled) = 12 then "December"
	end as `Month`,
    o.branchName as `Branch Name`,
    count(subscriptionid) as `Cancels`, -- Number of cancels
    sum(contractvalue) as `Contract Value` -- Contract value
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.office as o on o.officeid = s.officeid
where initialstatus = 1 and datecancelled >= '2022-01-01' and datecancelled <= now()
	and source in (
		"Thumbtack","Social Media","Marketing Email/Text","Local Service Ad (Google)",
		"Internet- WGL","Internet- Organic","Internet Search","Internet","HomeAdvisor","Google",
		"Dex Digital","Aktify"
	)
group by year(datecancelled), month(datecancelled), s.officeid
order by year(datecancelled) asc, month(datecancelled) asc, o.branchname asc;
;

/* Source exploration
select source
from dwh_reportsdb.subscription
where dateadded >= '2022-01-01'
group by source
;#*/