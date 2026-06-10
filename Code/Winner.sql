select 
	fname as `First Name`,
	lname as `Last Name`,
	email as `Email`,
	phone1 as `Phone`
from dwh_reportsdb.customer as c
where
	datediff("2025-09-19", c.datecancelled) > 60
	and dateadded >= "2025-01-01"
    and status = 0
    and length(email) > 5
group by email
;