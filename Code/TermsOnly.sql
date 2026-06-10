-- Code Crew: 30-day email subscribers relevant to termite plans

SELECT
    IF(c.status = 1, "Active", "Inactive") AS `Active Status`,
    c.customerid AS `Customer Id`,
    s.subscriptionid AS `Subscription Id`,
    c.email AS `Email`,
    c.phone1 AS `Phone`,
    c.dateadded AS `Start Date`,
    max(case when (s.servicetype like "%sentricon%" or s.servicetype like "%termite%") then s.servicetype end
		) AS `Service Type`,
    COUNT(s.subscriptionid) AS `Subscription Count`
FROM dwh_reportsdb.customer c
INNER JOIN dwh_reportsdb.subscription s
    ON s.customerid = c.customerid
    -- AND s.dateadded >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH) # Withint the last three months
WHERE
    -- c.dateadded >= DATE_SUB(CURDATE(), INTERVAL 3 MONTH) and # Within the last three months
    LENGTH(c.email) >= 5
    AND c.status = 1
    /* Filter offices
    and c.officeid in (
    -- Texas
    7, 11, 25,
    -- Louisiana
    4,19,23,28
    )#*/
GROUP BY c.email
HAVING SUM(
    CASE 
        WHEN (s.servicetype like "%sentricon%" or s.servicetype like "%termite%") 
        and s.active = 1 -- Is active
        THEN 1 ELSE 0 
    END
) 
	-- = 0 # No termite account
    > 0 # Have at least 1 termite account
    -- = 1 # Have one termite account
;

/*Looking for office ids
select *
from dwh_reportsdb.office
where branchName like "%FL%"
group by officeid
;#*/

/*Looking for service types
select servicetype
from dwh_reportsdb.subscription
group by servicetype
;#*/