-- HPP Recurring

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
        /* Commercial accounts
        'Commercial Protection Plan', 
        'Commercial Protection Plan - Initial', 
        'Commercial Protection Plan - ORGANIC'
			,#*/
        -- /* Non Commercial Accounts
        '5x Quarterly 5x Quarterly  GLOBAL', 
		'Do not useFox Home Protection Plan', 
        'Fox Home Protection Plan', 
        'Fox Home Protection Plan - Initial', 
        'Fox Home Protection Plan - ORGANIC',
		'Fox Home Protection Plan - ORGANIC INITIAL', 
        'Fox Home Protection Plan - PEST TUBES', 
        'Home Protection Plan', 
        'Home Protection Plan - Initial',
		'Home Protection Plan - ORGANIC', 
        'Organic HPP' #*/
        ))
        and s.active = 1 # Is active
        THEN 1 ELSE 0 
    END
) 
	-- = 0 # No relevant account
    > 0 # Have at least 1 relevant account
    -- = 1 # Have one relevant account
;
