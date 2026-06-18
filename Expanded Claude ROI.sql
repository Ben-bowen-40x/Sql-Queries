-- SET SESSION MAX_EXECUTION_TIME=300000;
-- SELECT @@SESSION.MAX_EXECUTION_TIME;

WITH cand_customers AS (
	SELECT DISTINCT customerid 
	FROM dwh_reportsdb.subscription 
	WHERE dateaddeddate >= '2026-01-01' AND initialstatus = 1
), all_subs AS ( -- classification: same-customerid only, no grouping
	SELECT 
		s.subscriptionID, s.customerID, s.customerid AS grp,
      s.dateAdded, s.dateAddedDate AS dadd_day,
      CASE
      	WHEN s.dateCancelled IS NULL                               THEN '9999-12-31 23:59:59'
         WHEN CAST(s.dateCancelled AS CHAR) = '0000-00-00 00:00:00' THEN '9999-12-31 23:59:59'
         ELSE s.dateCancelled
      END AS active_end,
      s.contractValue
	FROM dwh_reportsdb.subscription s
   WHERE s.initialStatus = 1 AND dateaddeddate >= '2026-01-01'
      AND s.customerid IN (SELECT customerid FROM cand_customers)   
), candidate_subs AS (
    SELECT s.subscriptionid, s.customerid, s.dateadded, s.contractvalue
    FROM dwh_reportsdb.subscription s
    WHERE s.customerid IN (SELECT customerid FROM cand_customers)
      AND s.dateaddeddate >= '2026-01-01' AND s.initialstatus = 1
), prior_active AS (
   SELECT DISTINCT curr.subscriptionID
   FROM all_subs curr
   JOIN all_subs prev
   	ON prev.grp = curr.grp
	AND prev.dadd_day < curr.dadd_day           -- DATE grain: prior day (same-day siblings excluded)
   AND prev.active_end >= curr.dateAdded       -- TIMESTAMP grain: still active
), prior_ever AS (
   SELECT DISTINCT curr.subscriptionID
   FROM all_subs curr
   JOIN all_subs prev
   	ON prev.grp = curr.grp
	AND prev.dadd_day < curr.dadd_day
), sub_status AS (
   SELECT s.subscriptionID,
   	CASE
      	WHEN pa.subscriptionID IS NOT NULL THEN 'upgrades'
         WHEN pe.subscriptionID IS NOT NULL THEN 'winback'
         ELSE 'new_acquisition'
      END AS status
   FROM all_subs s
   LEFT JOIN prior_active pa ON pa.subscriptionID = s.subscriptionID
   LEFT JOIN prior_ever  pe ON pe.subscriptionID = s.subscriptionID
), cand_phone_list AS (
	SELECT DISTINCT p10 FROM (
		SELECT RIGHT(c.phone1,10) AS p10
		FROM cand_customers cc 
			JOIN dwh_reportsdb.customer c ON c.customerid = cc.customerid
   UNION
		SELECT RIGHT(c.phone2,10) AS p10
      FROM cand_customers cc 
			JOIN dwh_reportsdb.customer c ON c.customerid = cc.customerid
    ) z
    WHERE CHAR_LENGTH(p10) = 10
),

-- ============================================================
-- THREE PHONE-MATCHED TOUCH CHANNELS (CTM now joins by phone, not ctmid)
-- Each pre-aggregated to earliest touch per phone, carrying its source label.
-- ============================================================
ctm_first AS (
   SELECT phone10, contact_pacific, src_label, 'ctm' AS `medium`
   FROM (
   	SELECT contact_number_clean AS phone10,
      CONVERT_TZ(called_at_utc,'+00:00','America/Los_Angeles') AS contact_pacific,
      source AS src_label
      FROM dwh_ctmdb.calls
      WHERE contact_number_clean IS NOT NULL
          AND RIGHT(contact_number_clean,10) IN (SELECT p10 FROM cand_phone_list)   -- filter BEFORE window
    ) x
), lf_first AS (
    SELECT phone10, contact_pacific, src_label, 'leadferno' AS `medium`
    FROM (
        SELECT right(phone,10) AS phone10,
               CONVERT_TZ(messageDate,'+00:00','America/Los_Angeles') AS contact_pacific,
               CASE
                   WHEN source LIKE '%gclid%'   THEN 'Google Ads Leadferno'
                   WHEN source LIKE '%msclkid%' THEN 'Microsoft Ads Leadferno'
                   ELSE 'Leadferno'
               END AS src_label
        FROM dwh_leadferno.leadferno_messages
    ) x
    WHERE right(x.phone10,10) IN (SELECT p10 FROM cand_phone_list)
), form_first AS (
    SELECT phone10, contact_pacific, src_label, 'contact forms' AS `medium`
    FROM (
        SELECT phoneNumber AS phone10,
               CONVERT_TZ(timestamp,'+00:00','America/Los_Angeles') AS contact_pacific,
               'Contact Form' AS src_label
        FROM dwh_internetmarketingdb.masterWebForm
        WHERE phoneNumber IS NOT NULL 
    ) x
    WHERE right(x.phone10,10) IN (SELECT p10 FROM cand_phone_list)
), contact_ranked AS ( -- cross-channel earliest touch per phone (the winning touch sets the source)
	SELECT phone10, contact_pacific AS first_contact, src_label, `medium`,
           ROW_NUMBER() OVER (PARTITION BY phone10 ORDER BY contact_pacific) AS rn
    FROM ( 
	 	SELECT * FROM ctm_first
           UNION ALL SELECT * FROM lf_first
           UNION ALL SELECT * FROM form_first ) u
    WHERE phone10 IS NOT NULL AND CHAR_LENGTH(phone10) = 10 AND phone10 <> '5555555555'
), contact_first AS (
    SELECT phone10, first_contact, src_label, `medium` FROM contact_ranked WHERE rn = 1
), cust_norm AS (
	SELECT c.customerid, RIGHT(c.phone1,10) AS phone10
		FROM cand_customers cc
		JOIN dwh_reportsdb.customer c ON c.customerid = cc.customerid
		WHERE c.phone1 IS NOT NULL AND CHAR_LENGTH(RIGHT(c.phone1,10)) = 10
	UNION
	SELECT c.customerid, RIGHT(c.phone2,10) AS phone10
		FROM cand_customers cc
		JOIN dwh_reportsdb.customer c ON c.customerid = cc.customerid
		WHERE c.phone2 IS NOT NULL AND CHAR_LENGTH(RIGHT(c.phone2,10)) = 10
), cust_contact_ranked AS (
    SELECT cn.customerid, cf.first_contact, cf.src_label, cf.medium, cf.phone10 AS lead_phone,
           ROW_NUMBER() OVER (PARTITION BY cn.customerid ORDER BY cf.first_contact) AS rn
    FROM cust_norm cn
    JOIN contact_first cf ON cf.phone10 = cn.phone10
), cust_contact AS (
    SELECT customerid, first_contact, src_label, `medium`, lead_phone FROM cust_contact_ranked WHERE rn = 1
),

-- ============================================================
-- FINAL: qualify on touch-before-sale; exclude current customers
-- ============================================================
claimed AS (
    SELECT
        cs.subscriptionid, cs.customerid, cs.dateadded, cs.contractvalue, cc.first_contact,
        ss.status,
        cc.medium,
        cc.src_label AS source
    FROM candidate_subs cs
    JOIN sub_status   ss ON ss.subscriptionid = cs.subscriptionid
    JOIN cust_contact cc ON cc.customerid     = cs.customerid    -- INNER: must have a touch
    WHERE cc.first_contact < cs.dateadded                        -- touch strictly before sale
)

/* 1. Is cust_contact actually one row per customer?
SELECT customerid, COUNT(*) AS rows_per_cust
FROM cust_contact
GROUP BY customerid
HAVING COUNT(*) > 1
LIMIT 20;#*/

/* 2. Is claimed duplicating subscriptions?
SELECT subscriptionid, COUNT(*) AS rows_per_sub
FROM claimed
GROUP BY subscriptionid
HAVING COUNT(*) > 1
LIMIT 20;#*/

/* aggregates for selected year
SELECT YEAR(first_contact) as YEAR, COUNT(*) AS total_sales, FORMAT(SUM(contractvalue),2) AS total_contract_value, status
FROM claimed
WHERE year(first_contact) = 2026
GROUP BY status;#*/

-- /* aggregates by year,month,source
SELECT
    YEAR(first_contact)  					AS year,
    MONTH(first_contact) 					AS month,
    source,
--     `status`,
    COUNT(*)                        AS total_sales,
    FORMAT(SUM(contractvalue), 2)   AS total_contract_value
FROM claimed
WHERE claimed.status <> 'upgrades'
GROUP BY YEAR(first_contact), MONTH(first_contact), `source` -- WITH ROLLUP
ORDER BY year, month, source;#*/