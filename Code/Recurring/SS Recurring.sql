-- Single Service Recurring

SELECT
    IF(c.status = 1, "Active", "Inactive") AS `Active Status`,
    c.customerid AS `Customer Id`,
    s.subscriptionid AS `Subscription Id`,
    c.email AS `Email`,
    c.phone1 AS `Phone`,
    c.dateadded AS `Start Date`,
    COUNT(s.subscriptionid) AS `Subscription Count`
FROM dwh_reportsdb.customer c
INNER JOIN dwh_reportsdb.subscription s
    ON s.customerid = c.customerid
WHERE
    LENGTH(c.email) >= 5
    AND c.status = 1
GROUP BY c.email
HAVING SUM(
    CASE 
        WHEN (s.servicetype in (
        /* Commercial
        'Commercial - Single Service',
		'Commercial - Single Service YEP'
			,#*/
        -- /*Non commercial
		'Single Service',
		'Single Service YEP'#*/
        ))
        and s.active = 1 # Is active
        THEN 1 ELSE 0 
    END
) 
	-- = 0 # No relevant account
    > 0 # Have at least 1 relevant account
    -- = 1 # Have one relevant account
;
