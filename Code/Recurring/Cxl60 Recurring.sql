-- 60-day cancels

SELECT
    IF(c.status = 1, "Active", "Inactive") AS `Active Status`,
    c.customerid AS `Customer Id`,
    c.email AS `Email`,
    c.phone1 AS `Phone`,
    c.dateadded AS `Start Date`,
    c.dateCancelled as `Cancel Date`
FROM dwh_reportsdb.customer c
WHERE
    LENGTH(c.email) >= 5
    and c.email not like '%fox-pest.com%'
    and c.status = 0
    and commercialAccount = 0
    and c.dateCancelled >= date_sub(curdate(), interval 60 day)
    and not exists(
		select 1 from dwh_reportsdb.subscription s
        where s.customerid = c.customerid
			and s.initialStatus = 1
        )
GROUP BY c.email
;
