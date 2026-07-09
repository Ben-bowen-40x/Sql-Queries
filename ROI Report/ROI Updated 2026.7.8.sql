-- ===================================================================
-- Configuration: File-wide variable declarations
-- ===================================================================
-- Every year, the table will only be able to see four years back. 
-- To see earlier years, change @population_epoch value to 'yyyy-MM-DD' format (hardcoded),
-- or adjust the formula to include the desired year.
-- Keep in mind that extending the population_epoch will increase the execution time
-- NOTE: with the rolling formula, years age out of the table permanently each Jan 1.
-- Aged-out years can only be reconstructed by rerunning with an older epoch.
SET @population_epoch := MAKEDATE(YEAR(CURDATE()) - 4, 1); -- Originally, 4 years ago (based on current year): MAKEDATE(YEAR(CURDATE()) - 4, 1)
SET @window_end 		 := MAKEDATE(YEAR(CURDATE()) + 1, 1); -- Originally, Jan 1 next year (based on current year): MAKEDATE(YEAR(CURDATE()) + 1, 1)

-- ===================================================================
-- STEP 1: Materialize all touches joined to customers, WITH INDEX.
-- This is the expensive build (~40-60s) but it happens exactly once,
-- and the index makes every downstream lookup a seek instead of a scan.
-- ===================================================================
DROP TEMPORARY TABLE IF EXISTS tmp_cust_touches;

CREATE TEMPORARY TABLE tmp_cust_touches
  (INDEX idx_cust_time (cust_customerid, touch_first_contact))
AS
WITH cand_customers AS (
  SELECT DISTINCT customerid
  FROM dwh_reportsdb.subscription
  WHERE dateaddeddate >= @population_epoch AND initialstatus = 1
),
cand_phone_list AS (
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
ctm_first AS (
  SELECT
    ctm_phone10, ctm_contact_pacific, ctm_source,
    'ctm' AS touch_medium,
    ctm_call_id,
    ctm_contact_number, ctm_location, ctm_referrer, ctm_campaign,
    NULL AS wbf_referring_url, NULL AS wbf_source, NULL AS wbf_medium, NULL AS wbf_campaign,
    NULL AS wbf_utm_content, NULL AS wbf_utm_term, NULL AS wbf_form_name, NULL AS wbf_contact_name,
    NULL AS wbf_hearded_about, NULL AS wbf_referred_by, NULL AS wbf_current_customer, NULL AS wbf_commercial
  FROM (
    SELECT
      contact_number_clean AS ctm_phone10,
      CONVERT_TZ(called_at_utc,'+00:00','America/Los_Angeles') AS ctm_contact_pacific,
      source AS ctm_source,
      call_id AS ctm_call_id,
      contact_number AS ctm_contact_number,
      location AS ctm_location,
      referrer AS ctm_referrer,
      campaign AS ctm_campaign
    FROM dwh_ctmdb.calls
    WHERE contact_number_clean IS NOT NULL
      AND RIGHT(contact_number_clean,10) IN (SELECT p10 FROM cand_phone_list)
  ) x
),
lf_first AS (
  SELECT
    lf_phone10, lf_contact_pacific, lf_source,
    'leadferno' AS touch_medium,
    NULL AS ctm_call_id,
    NULL AS ctm_contact_number, NULL AS ctm_location, NULL AS ctm_referrer, NULL AS ctm_campaign,
    NULL AS wbf_referring_url, NULL AS wbf_source, NULL AS wbf_medium, NULL AS wbf_campaign,
    NULL AS wbf_utm_content, NULL AS wbf_utm_term, NULL AS wbf_form_name, NULL AS wbf_contact_name,
    NULL AS wbf_hearded_about, NULL AS wbf_referred_by, NULL AS wbf_current_customer, NULL AS wbf_commercial
  FROM (
    SELECT
      RIGHT(phone,10) AS lf_phone10,
      CONVERT_TZ(messageDate,'+00:00','America/Los_Angeles') AS lf_contact_pacific,
      CASE
        WHEN source LIKE '%gclid%' THEN 'Google Ads Leadferno'
        WHEN source LIKE '%msclkid%' THEN 'Microsoft Ads Leadferno'
        ELSE 'Leadferno'
      END AS lf_source
    FROM dwh_leadferno.leadferno_messages
  ) x
  WHERE RIGHT(x.lf_phone10,10) IN (SELECT p10 FROM cand_phone_list)
),
form_first AS (
  SELECT
    wbf_phone10, wbf_contact_pacific, wbf_src_label,
    'contact forms' AS touch_medium,
    NULL AS ctm_call_id,
    NULL AS ctm_contact_number, NULL AS ctm_location, NULL AS ctm_referrer, NULL AS ctm_campaign,
    wbf_referring_url, wbf_source, wbf_medium, wbf_campaign,
    wbf_utm_content, wbf_utm_term, wbf_form_name, wbf_contact_name,
    wbf_hearded_about, wbf_referred_by, wbf_current_customer, wbf_commercial
  FROM (
    SELECT
      phoneNumber AS wbf_phone10,
      CONVERT_TZ(timestamp,'+00:00','America/Los_Angeles') AS wbf_contact_pacific,
      CASE
        WHEN source LIKE '%gclid%' THEN 'Google Ads Form'
        WHEN source LIKE '%msclkid%' THEN 'Microsoft Ads Form'
        WHEN medium IS NOT NULL THEN CONCAT('Form: ', medium)
        ELSE 'Contact Form'
      END AS wbf_src_label,
      referringURL AS wbf_referring_url, source AS wbf_source, medium AS wbf_medium,
      campaign AS wbf_campaign, utmContent AS wbf_utm_content, utmTerm AS wbf_utm_term,
      formName AS wbf_form_name, CONCAT(firstName, ' ', lastName) AS wbf_contact_name,
      hearedAbout AS wbf_hearded_about, referredBy AS wbf_referred_by,
      currentCustomer AS wbf_current_customer, commercial AS wbf_commercial
    FROM dwh_internetmarketingdb.masterWebForm
    WHERE phoneNumber IS NOT NULL
  ) x
  WHERE RIGHT(x.wbf_phone10,10) IN (SELECT p10 FROM cand_phone_list)
),
all_touches AS (
  SELECT
    ctm_phone10 AS touch_phone10, ctm_contact_pacific AS touch_first_contact,
    ctm_source AS touch_source, touch_medium, ctm_call_id,
    ctm_contact_number, ctm_location, ctm_referrer, ctm_campaign,
    wbf_referring_url, wbf_source, wbf_medium, wbf_campaign,
    wbf_utm_content, wbf_utm_term, wbf_form_name, wbf_contact_name,
    wbf_hearded_about, wbf_referred_by, wbf_current_customer, wbf_commercial
  FROM ctm_first
  UNION ALL
  SELECT
    lf_phone10, lf_contact_pacific, lf_source, touch_medium, ctm_call_id,
    ctm_contact_number, ctm_location, ctm_referrer, ctm_campaign,
    wbf_referring_url, wbf_source, wbf_medium, wbf_campaign,
    wbf_utm_content, wbf_utm_term, wbf_form_name, wbf_contact_name,
    wbf_hearded_about, wbf_referred_by, wbf_current_customer, wbf_commercial
  FROM lf_first
  UNION ALL
  SELECT
    wbf_phone10, wbf_contact_pacific, wbf_src_label, touch_medium, ctm_call_id,
    ctm_contact_number, ctm_location, ctm_referrer, ctm_campaign,
    wbf_referring_url, wbf_source, wbf_medium, wbf_campaign,
    wbf_utm_content, wbf_utm_term, wbf_form_name, wbf_contact_name,
    wbf_hearded_about, wbf_referred_by, wbf_current_customer, wbf_commercial
  FROM form_first
),
cust_norm AS (
  SELECT c.customerid AS cust_customerid, RIGHT(c.phone1,10) AS cust_phone10
  FROM cand_customers cc
  JOIN dwh_reportsdb.customer c ON c.customerid = cc.customerid
  WHERE c.phone1 IS NOT NULL AND CHAR_LENGTH(RIGHT(c.phone1,10)) = 10
  UNION
  SELECT c.customerid AS cust_customerid, RIGHT(c.phone2,10) AS cust_phone10
  FROM cand_customers cc
  JOIN dwh_reportsdb.customer c ON c.customerid = cc.customerid
  WHERE c.phone2 IS NOT NULL AND CHAR_LENGTH(RIGHT(c.phone2,10)) = 10
)
SELECT
  cn.cust_customerid,
  t.touch_phone10, t.touch_first_contact, t.touch_source, t.touch_medium, t.ctm_call_id,
  t.ctm_contact_number, t.ctm_location, t.ctm_referrer, t.ctm_campaign,
  t.wbf_referring_url, t.wbf_source, t.wbf_medium, t.wbf_campaign,
  t.wbf_utm_content, t.wbf_utm_term, t.wbf_form_name, t.wbf_contact_name,
  t.wbf_hearded_about, t.wbf_referred_by, t.wbf_current_customer, t.wbf_commercial
FROM all_touches t
JOIN cust_norm cn ON cn.cust_phone10 = t.touch_phone10
WHERE t.touch_phone10 IS NOT NULL
  AND CHAR_LENGTH(t.touch_phone10) = 10
  AND t.touch_phone10 <> '5555555555';


-- ===================================================================
-- STEP 2: Customer's first-ever sub date — ANY initialStatus, ANY date.
-- A failed sub still anchors origin: IM found the lead even if ops lost the close.
-- ===================================================================
DROP TEMPORARY TABLE IF EXISTS tmp_first_sub;

CREATE TEMPORARY TABLE tmp_first_sub
  (INDEX idx_cust (customerid))
AS
SELECT s.customerid, MIN(s.dateAdded) AS first_sub_date
FROM dwh_reportsdb.subscription s
WHERE s.customerid IN (SELECT DISTINCT customerid
                       FROM dwh_reportsdb.subscription
                       WHERE dateaddeddate >= @population_epoch AND initialstatus = 1)
GROUP BY s.customerid;


-- ===================================================================
-- STEP 3: Customers provably acquired by IM (touch BEFORE first-ever sub).
-- Materialized separately because MySQL can't reference a temp table
-- twice in one query — this keeps tmp_cust_touches to one use in Step 4.
-- EXISTS + index = one seek per customer.
-- ===================================================================
DROP TEMPORARY TABLE IF EXISTS tmp_orig_attributed;

CREATE TEMPORARY TABLE tmp_orig_attributed
  (INDEX idx_cust (customerid))
AS
SELECT fs.customerid
FROM tmp_first_sub fs
WHERE EXISTS (
  SELECT 1 FROM tmp_cust_touches ct
  WHERE ct.cust_customerid = fs.customerid
    AND ct.touch_first_contact < fs.first_sub_date
);


-- ===================================================================
-- STEP 4: Main query.
-- IM first-touch attribution, one row per subscription (sale).
-- Revenue cohorted by TOUCH date, not sale date.
-- Statuses: new_acquisition / winback (provable IM origin) / upgrades.
-- ===================================================================
WITH cand_customers AS (
  SELECT DISTINCT customerid
  FROM dwh_reportsdb.subscription
  WHERE dateaddeddate >= @population_epoch AND initialstatus = 1
),
-- All-time, status=1 history. NO date filter — all-time or winbacks misclassify (bug fixed 2026-07-07).
all_subs AS (
  SELECT
    s.subscriptionID AS sub_id, s.customerID AS sub_customerid, s.customerid AS grp,
    s.dateAdded AS sub_dateadded, s.dateAddedDate AS sub_dateadded_day,
    CASE
      WHEN s.dateCancelled IS NULL THEN '9999-12-31 23:59:59'
      WHEN CAST(s.dateCancelled AS CHAR) = '0000-00-00 00:00:00' THEN '9999-12-31 23:59:59'
      ELSE s.dateCancelled
    END AS sub_active_end,
    s.contractValue AS sub_contractvalue
  FROM dwh_reportsdb.subscription s
  WHERE s.initialStatus = 1
    AND s.customerid IN (SELECT customerid FROM cand_customers)
),

-- Reported population: subscriptions from [year] or later where status=1.
candidate_subs AS (
  SELECT s.subscriptionid AS sub_id, s.customerid AS sub_customerid,
    s.dateadded AS sub_dateadded, s.contractvalue AS sub_contractvalue,
    s.officeID AS sub_officeid
  FROM dwh_reportsdb.subscription s
  WHERE s.customerid IN (SELECT customerid FROM cand_customers)
    AND s.dateaddeddate >= @population_epoch AND s.initialstatus = 1
-- The subscription table only updates once a day around midnight,
-- and sometimes salespeople put the s.dateadded/s.dateaddeddate for a future date.
-- The filter here prevents future-dated s.dateadded/s.dateaddeddate from clogging results.
-- Putting the filter later is less efficient than putting it here
	 AND s.dateaddeddate < CURDATE()
),
prior_active AS (
  SELECT DISTINCT curr.sub_id
  FROM all_subs curr
  JOIN all_subs prev ON prev.grp = curr.grp
    AND prev.sub_dateadded_day < curr.sub_dateadded_day
    AND prev.sub_active_end >= curr.sub_dateadded
),
prior_ever AS (
  SELECT DISTINCT curr.sub_id
  FROM all_subs curr
  JOIN all_subs prev ON prev.grp = curr.grp
    AND prev.sub_dateadded_day < curr.sub_dateadded_day
),
sub_status AS (
  SELECT s.sub_id,
    CASE
      WHEN pa.sub_id IS NOT NULL THEN 'upgrades'
      WHEN pe.sub_id IS NOT NULL THEN 'winback'
      ELSE 'new_acquisition'
    END AS sub_status
  FROM all_subs s
  LEFT JOIN prior_active pa ON pa.sub_id = s.sub_id
  LEFT JOIN prior_ever pe ON pe.sub_id = s.sub_id
),

-- winback_floor = latest prior CANCEL; upgrade_floor = latest prior START.
prior_floor AS (
  SELECT curr.sub_id,
         MAX(CAST(prev.sub_active_end AS DATETIME)) AS winback_floor,
         MAX(prev.sub_dateadded)                     AS upgrade_floor
  FROM all_subs curr
  JOIN all_subs prev
    ON prev.grp = curr.grp
   AND prev.sub_dateadded_day < curr.sub_dateadded_day
  GROUP BY curr.sub_id
),

-- PER-SUB attribution: earliest touch in each sub's window. rn=1 wins.
--   new_acquisition: any touch < sub_dateadded
--   upgrades:        upgrade_floor <= touch < sub_dateadded
--   winback:         winback_floor <= touch < sub_dateadded AND provable IM origin
-- No qualifying touch → no row → excluded from report.
sub_touch_ranked AS (
  SELECT
    cs.sub_id, cs.sub_customerid, cs.sub_dateadded, cs.sub_contractvalue, cs.sub_officeid,
    ss.sub_status,
    ct.touch_phone10, ct.touch_first_contact, ct.touch_source, ct.touch_medium, ct.ctm_call_id,
    ct.ctm_contact_number, ct.ctm_location, ct.ctm_referrer, ct.ctm_campaign,
    ct.wbf_referring_url, ct.wbf_source, ct.wbf_medium, ct.wbf_campaign,
    ct.wbf_utm_content, ct.wbf_utm_term, ct.wbf_form_name, ct.wbf_contact_name,
    ct.wbf_hearded_about, ct.wbf_referred_by, ct.wbf_current_customer, ct.wbf_commercial,
    ROW_NUMBER() OVER (PARTITION BY cs.sub_id ORDER BY ct.touch_first_contact ASC) AS rn
  FROM candidate_subs cs
  JOIN sub_status ss ON ss.sub_id = cs.sub_id
  LEFT JOIN prior_floor pf ON pf.sub_id = cs.sub_id
  LEFT JOIN tmp_orig_attributed oa ON oa.customerid = cs.sub_customerid
  JOIN tmp_cust_touches ct ON ct.cust_customerid = cs.sub_customerid
  WHERE ct.touch_first_contact < cs.sub_dateadded
    AND (
         ss.sub_status = 'new_acquisition'
      OR (ss.sub_status = 'upgrades'
          AND ct.touch_first_contact >= pf.upgrade_floor)
      OR (ss.sub_status = 'winback'
          AND ct.touch_first_contact >= pf.winback_floor
          AND oa.customerid IS NOT NULL)
    )
),
sub_touch AS (
  SELECT * FROM sub_touch_ranked WHERE rn = 1
),
-- All dates Pacific (touches converted; dateAdded/dateCancelled stored Pacific — verified 2026-07).
claimed AS (
  SELECT
    st.sub_id, st.sub_customerid, st.sub_dateadded, st.sub_contractvalue, st.sub_officeid,
    ofc.branchName AS ofc_branchname,
    c.phone1 AS cust_phone1, c.phone2 AS cust_phone2,
    st.sub_status,
    st.touch_first_contact, st.touch_source, st.touch_medium,
    st.touch_phone10 AS touch_phone,
    st.ctm_call_id,
    CASE
      WHEN st.touch_source IN ('Google Adwords','Ad Extension','Google Call Extension','call only','Google Call Asset','Google Ads') THEN 'Google Ads'
      WHEN st.touch_source = 'wgl' THEN 'WGL'
      WHEN st.touch_source = 'website' THEN 'Website'
      WHEN st.touch_source = 'Direct' THEN 'Direct'
      WHEN st.touch_source IN ('GMB','GMB ','GMB - Glen Ellyn, IL 60137','Google My Business','GMB Post','GMB - Gurnee, IL 60031','North Chicago GMB','GMB - Brownsville','GMB - Newport News','Google Business Profile - Website Visitor','Google Business Profile - Static Number') THEN 'GBP'
      WHEN st.touch_source IN ('facebook paid','General Meta Ads') THEN 'Meta Ads'
      WHEN st.touch_source IN ('Facebook video','Facebook Ads','facebook') THEN 'Facebook Organic'
      WHEN st.touch_source = 'Google LSA' THEN 'Google LSA'
      WHEN st.touch_source = 'Google organic' THEN 'Google Organic'
      WHEN st.touch_source = 'PestNet' THEN 'PestNet'
      WHEN st.touch_source = 'elocal' THEN 'Elocal'
      WHEN st.touch_source = 'Goodzer' THEN 'Goodzer'
      WHEN st.touch_source = 'email' THEN 'Email'
      WHEN TRIM(st.touch_source) = '' THEN 'National Leads'
      WHEN st.touch_source LIKE '%biz%' THEN 'Local Biz'
      WHEN st.touch_source IN ('bing','BING Paid','Bing Organic','Bing Call Extensions') THEN 'Microsoft Ads'
      WHEN LOWER(st.touch_source) LIKE '%service%direct%' THEN 'Service Direct'
      WHEN st.touch_source LIKE '%Google Ads Leadferno%' THEN 'Google Ads'
      WHEN st.touch_source LIKE '%Microsoft Ads Leadferno%' THEN 'Microsoft Ads'
      WHEN st.touch_source = 'Leadferno' THEN 'Leadferno'
      WHEN st.touch_source LIKE '%Google Ads Form%' THEN 'Google Ads'
      WHEN st.touch_source LIKE '%Microsoft Ads Form%' THEN 'Microsoft Ads'
      WHEN st.touch_source = 'Contact Form' THEN 'Contact Form'
      WHEN st.touch_source LIKE 'Form:%' THEN st.touch_source
      ELSE st.touch_source
    END AS normalized_source,
    CASE
      WHEN st.touch_source IN ('Google Adwords','Ad Extension','Google Call Extension','call only','Google Call Asset','Google Ads') THEN 'Paid'
      WHEN st.touch_source = 'wgl' THEN 'Paid'
      WHEN st.touch_source = 'website' THEN 'Non-Paid'
      WHEN st.touch_source = 'Direct' THEN 'Non-Paid'
      WHEN st.touch_source IN ('GMB','GMB ','GMB - Glen Ellyn, IL 60137','Google My Business','GMB Post','GMB - Gurnee, IL 60031','North Chicago GMB','GMB - Brownsville','GMB - Newport News') THEN 'Non-Paid'
      WHEN st.touch_source IN ('facebook paid','General Meta Ads') THEN 'Paid'
      WHEN st.touch_source IN ('Facebook video','Facebook Ads','facebook') THEN 'Paid'
      WHEN st.touch_source = 'Google LSA' THEN 'Paid'
      WHEN st.touch_source = 'Google organic' THEN 'Non-Paid'
      WHEN st.touch_source = 'PestNet' THEN 'Paid'
      WHEN st.touch_source = 'Elocal' THEN 'Paid'
      WHEN st.touch_source = 'Goodzer' THEN 'Paid'
      WHEN st.touch_source = 'email' THEN 'Non-Paid'
      WHEN TRIM(st.touch_source) = '' THEN 'Paid'
      WHEN st.touch_source LIKE '%biz%' THEN 'Paid'
      WHEN st.touch_source IN ('Bing Paid','Bing Organic','Bing Call Extensions','Bing','Local Biz Emails','LocalBizCslls') THEN 'Paid'
      WHEN LOWER(st.touch_source) LIKE '%service%direct%' THEN 'Paid'
      WHEN st.touch_source = 'Aragon' THEN 'Paid'
      WHEN st.touch_source = 'Consumer Affairs' THEN 'Paid'
      WHEN st.touch_source LIKE '%Google Ads Leadferno%' THEN 'Paid'
      WHEN st.touch_source LIKE '%Microsoft Ads Leadferno%' THEN 'Paid'
      WHEN st.touch_source = 'Leadferno' THEN 'Non-Paid'
      WHEN st.touch_source LIKE '%Google Ads Form%' THEN 'Paid'
      WHEN st.touch_source LIKE '%Microsoft Ads Form%' THEN 'Paid'
      WHEN st.touch_source = 'Contact Form' THEN 'Non-Paid'
      WHEN st.touch_source LIKE 'Form:%' THEN 'Non-Paid'
      ELSE 'Non-Paid'
    END AS paid_type,
    st.ctm_contact_number, st.ctm_location, st.ctm_referrer, st.ctm_campaign,
    st.wbf_referring_url, st.wbf_source, st.wbf_medium, st.wbf_campaign,
    st.wbf_utm_content, st.wbf_utm_term, st.wbf_form_name, st.wbf_contact_name,
    st.wbf_hearded_about, st.wbf_referred_by, st.wbf_current_customer, st.wbf_commercial
  FROM sub_touch st
  LEFT JOIN dwh_reportsdb.office ofc ON ofc.officeID = st.sub_officeid
  LEFT JOIN dwh_reportsdb.customer c ON c.customerID = st.sub_customerid
  WHERE st.touch_first_contact >= @population_epoch
    AND st.touch_first_contact <  @window_end
)

-- Prod select 
-- SELECT *  FROM claimed;

-- /* Aggregates -- must not survive beyond testing
SELECT
  YEAR(touch_first_contact)            AS touch_year,
--   MONTH(touch_first_contact)           AS touch_month,
  sub_status,
  COUNT(*)                             AS sales,
  FORMAT(SUM(sub_contractvalue), 2)    AS contract_value -- This is here for viewing convenience
FROM claimed
GROUP BY 
	touch_year, 
-- 	touch_month, 
	sub_status
ORDER BY 
	touch_year, 
-- 	touch_month, 
	sub_status; 
-- */

-- /* Temporary tables do not need to stay through the end of the session, especially when handed off
-- Comment these out for future checking.
DROP TEMPORARY TABLE tmp_cust_touches;
DROP TEMPORARY TABLE tmp_first_sub;
DROP TEMPORARY TABLE tmp_orig_attributed;
-- */