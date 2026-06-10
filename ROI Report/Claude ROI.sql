WITH
candidate_custs AS (
    SELECT DISTINCT customerid
    FROM dwh_reportsdb.subscription
    WHERE dateadded >= '2026-01-01' AND initialstatus = 1
),
all_subs AS (
    SELECT s.subscriptionID, s.customerID, s.customerid AS grp,
           s.dateAdded, s.dateAddedDate AS dadd_day,
           CASE
               WHEN s.dateCancelled IS NULL                               THEN '9999-12-31 23:59:59'
               WHEN CAST(s.dateCancelled AS CHAR) = '0000-00-00 00:00:00' THEN '9999-12-31 23:59:59'
               ELSE s.dateCancelled
           END AS active_end,
           s.contractValue
    FROM dwh_reportsdb.subscription s
    WHERE s.initialStatus = 1
      AND s.customerid IN (SELECT customerid FROM candidate_custs)
),
prior_active AS (
    SELECT DISTINCT curr.subscriptionID
    FROM all_subs curr
    JOIN all_subs prev
      ON prev.grp = curr.grp
     AND prev.dadd_day < curr.dadd_day
     AND prev.active_end >= curr.dateAdded
),
prior_ever AS (
    SELECT DISTINCT curr.subscriptionID
    FROM all_subs curr
    JOIN all_subs prev
      ON prev.grp = curr.grp
     AND prev.dadd_day < curr.dadd_day
),
sub_status AS (
    SELECT s.subscriptionID,
        CASE
            WHEN pa.subscriptionID IS NOT NULL THEN 'current_customer'
            WHEN pe.subscriptionID IS NOT NULL THEN 'winback'
            ELSE 'new_acquisition'
        END AS status
    FROM all_subs s
    LEFT JOIN prior_active pa ON pa.subscriptionID = s.subscriptionID
    LEFT JOIN prior_ever  pe ON pe.subscriptionID = s.subscriptionID
),
candidate_subs AS (
    SELECT s.subscriptionid, s.customerid, s.dateadded, s.contractvalue
    FROM dwh_reportsdb.subscription s
    WHERE s.dateadded >= '2026-01-01' AND s.initialstatus = 1
),
-- spine, CALL-ATTRIBUTED ONLY: require a ctmid (this is the scope restriction)
sf_match AS (
    SELECT cs.subscriptionid,
           MIN(sf.ctmid) AS ctmid
    FROM candidate_subs cs
    JOIN dwh_salesforce.MarketingSalesforceLeads sf
      ON sf.pestroutessubscriptionid = cs.subscriptionid
    WHERE sf.qualifiedleadid IS NOT NULL
      AND sf.existingaccount = 0
--       AND sf.ctmid IS NOT NULL                       -- call-attributed only
    GROUP BY cs.subscriptionid
),
ctm_src AS (
    SELECT call_id, source AS ctm_source
    FROM (
        SELECT call_id, source,
               ROW_NUMBER() OVER (PARTITION BY call_id ORDER BY called_at_utc) AS rn
        FROM dwh_ctmdb.calls
        WHERE call_id IN (SELECT ctmid FROM sf_match WHERE ctmid IS NOT NULL)
    ) t
    WHERE rn = 1
),
claimed AS (
    SELECT
        cs.subscriptionid, cs.customerid, cs.dateadded, cs.contractvalue,
        ss.status,
        COALESCE(NULLIF(cx.ctm_source,''), 'Unknown') AS source
    FROM candidate_subs cs
    JOIN sub_status ss ON ss.subscriptionid = cs.subscriptionid
    JOIN sf_match   sm ON sm.subscriptionid = cs.subscriptionid     -- INNER: spine + call-attributed
    LEFT JOIN ctm_src cx ON cx.call_id = sm.ctmid
    WHERE ss.status <> 'current_customer'
)
/*
SELECT
    YEAR(dateadded)  AS year,
    MONTH(dateadded) AS month,
    source,
    COUNT(*)                        AS total_sales,
    FORMAT(SUM(contractvalue), 2)   AS total_contract_value
FROM claimed
GROUP BY YEAR(dateadded), MONTH(dateadded), source WITH ROLLUP
ORDER BY year, month, SOURCE;#*/

SELECT * FROM claimed;