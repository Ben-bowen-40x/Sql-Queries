WITH cand_customers AS (
  SELECT DISTINCT customerid
  FROM dwh_reportsdb.subscription
  WHERE dateaddeddate >= '2026-01-01' AND initialstatus = 1
), all_subs AS (
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
), candidate_subs AS (
  SELECT s.subscriptionid AS sub_id, s.customerid AS sub_customerid,
    s.dateadded AS sub_dateadded, s.contractvalue AS sub_contractvalue,
    s.officeID AS sub_officeid
  FROM dwh_reportsdb.subscription s
  WHERE s.customerid IN (SELECT customerid FROM cand_customers)
    AND s.dateaddeddate >= '2026-01-01' AND s.initialstatus = 1
), prior_active AS (
  SELECT DISTINCT curr.sub_id
  FROM all_subs curr
  JOIN all_subs prev ON prev.grp = curr.grp
    AND prev.sub_dateadded_day < curr.sub_dateadded_day
    AND prev.sub_active_end >= curr.sub_dateadded
), prior_ever AS (
  SELECT DISTINCT curr.sub_id
  FROM all_subs curr
  JOIN all_subs prev ON prev.grp = curr.grp
    AND prev.sub_dateadded_day < curr.sub_dateadded_day
), sub_status AS (
  SELECT s.sub_id,
    CASE
      WHEN pa.sub_id IS NOT NULL THEN 'upgrades'
      WHEN pe.sub_id IS NOT NULL THEN 'winback'
      ELSE 'new_acquisition'
    END AS sub_status
  FROM all_subs s
  LEFT JOIN prior_active pa ON pa.sub_id = s.sub_id
  LEFT JOIN prior_ever pe ON pe.sub_id = s.sub_id
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
-- TOUCH CHANNEL 1: dwh_ctmdb.calls
-- ============================================================
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
-- ============================================================
-- TOUCH CHANNEL 2: dwh_leadferno.leadferno_messages
-- ============================================================
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
-- ============================================================
-- TOUCH CHANNEL 3: dwh_internetmarketingdb.masterWebForm
-- ============================================================
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
-- ============================================================
-- RANKING: earliest touch per phone across all channels
-- ============================================================
contact_ranked AS (
  SELECT
    touch_phone10, touch_first_contact, touch_source, touch_medium,
    ctm_call_id,
    ctm_contact_number, ctm_location, ctm_referrer, ctm_campaign,
    wbf_referring_url, wbf_source, wbf_medium, wbf_campaign,
    wbf_utm_content, wbf_utm_term, wbf_form_name, wbf_contact_name,
    wbf_hearded_about, wbf_referred_by, wbf_current_customer, wbf_commercial,
    ROW_NUMBER() OVER (PARTITION BY touch_phone10 ORDER BY touch_first_contact) AS rn
  FROM (
    SELECT
      ctm_phone10 AS touch_phone10, ctm_contact_pacific AS touch_first_contact,
      ctm_source AS touch_source, touch_medium,
      ctm_call_id,
      ctm_contact_number, ctm_location, ctm_referrer, ctm_campaign,
      wbf_referring_url, wbf_source, wbf_medium, wbf_campaign,
      wbf_utm_content, wbf_utm_term, wbf_form_name, wbf_contact_name,
      wbf_hearded_about, wbf_referred_by, wbf_current_customer, wbf_commercial
    FROM ctm_first
    UNION ALL
    SELECT
      lf_phone10 AS touch_phone10, lf_contact_pacific AS touch_first_contact,
      lf_source AS touch_source, touch_medium,
      ctm_call_id,
      ctm_contact_number, ctm_location, ctm_referrer, ctm_campaign,
      wbf_referring_url, wbf_source, wbf_medium, wbf_campaign,
      wbf_utm_content, wbf_utm_term, wbf_form_name, wbf_contact_name,
      wbf_hearded_about, wbf_referred_by, wbf_current_customer, wbf_commercial
    FROM lf_first
    UNION ALL
    SELECT
      wbf_phone10 AS touch_phone10, wbf_contact_pacific AS touch_first_contact,
      wbf_src_label AS touch_source, touch_medium,
      ctm_call_id,
      ctm_contact_number, ctm_location, ctm_referrer, ctm_campaign,
      wbf_referring_url, wbf_source, wbf_medium, wbf_campaign,
      wbf_utm_content, wbf_utm_term, wbf_form_name, wbf_contact_name,
      wbf_hearded_about, wbf_referred_by, wbf_current_customer, wbf_commercial
    FROM form_first
  ) u
  WHERE touch_phone10 IS NOT NULL
    AND CHAR_LENGTH(touch_phone10) = 10
    AND touch_phone10 <> '5555555555'
), contact_first AS (
  SELECT
    touch_phone10, touch_first_contact, touch_source, touch_medium,
    ctm_call_id,
    ctm_contact_number, ctm_location, ctm_referrer, ctm_campaign,
    wbf_referring_url, wbf_source, wbf_medium, wbf_campaign,
    wbf_utm_content, wbf_utm_term, wbf_form_name, wbf_contact_name,
    wbf_hearded_about, wbf_referred_by, wbf_current_customer, wbf_commercial
  FROM contact_ranked
  WHERE rn = 1
), cust_norm AS (
  SELECT c.customerid AS cust_customerid, RIGHT(c.phone1,10) AS cust_phone10
  FROM cand_customers cc
  JOIN dwh_reportsdb.customer c ON c.customerid = cc.customerid
  WHERE c.phone1 IS NOT NULL AND CHAR_LENGTH(RIGHT(c.phone1,10)) = 10
  UNION
  SELECT c.customerid AS cust_customerid, RIGHT(c.phone2,10) AS cust_phone10
  FROM cand_customers cc
  JOIN dwh_reportsdb.customer c ON c.customerid = cc.customerid
  WHERE c.phone2 IS NOT NULL AND CHAR_LENGTH(RIGHT(c.phone2,10)) = 10
), cust_contact_ranked AS (
  SELECT
    cn.cust_customerid, cn.cust_phone10,
    cf.touch_first_contact, cf.touch_source, cf.touch_medium,
    cf.ctm_call_id,
    cf.ctm_contact_number, cf.ctm_location, cf.ctm_referrer, cf.ctm_campaign,
    cf.wbf_referring_url, cf.wbf_source, cf.wbf_medium, cf.wbf_campaign,
    cf.wbf_utm_content, cf.wbf_utm_term, cf.wbf_form_name, cf.wbf_contact_name,
    cf.wbf_hearded_about, cf.wbf_referred_by, cf.wbf_current_customer, cf.wbf_commercial,
    ROW_NUMBER() OVER (PARTITION BY cn.cust_customerid ORDER BY cf.touch_first_contact) AS rn
  FROM cust_norm cn
  JOIN contact_first cf ON cf.touch_phone10 = cn.cust_phone10
), cust_contact AS (
  SELECT
    cust_customerid, cust_phone10, touch_first_contact, touch_source, touch_medium,
    ctm_call_id,
    ctm_contact_number, ctm_location, ctm_referrer, ctm_campaign,
    wbf_referring_url, wbf_source, wbf_medium, wbf_campaign,
    wbf_utm_content, wbf_utm_term, wbf_form_name, wbf_contact_name,
    wbf_hearded_about, wbf_referred_by, wbf_current_customer, wbf_commercial
  FROM cust_contact_ranked
  WHERE rn = 1
),
-- ============================================================
-- FINAL: claimed — touch before sale
-- ============================================================
claimed AS (
  SELECT
    cs.sub_id, cs.sub_customerid, cs.sub_dateadded, cs.sub_contractvalue, cs.sub_officeid,
    ofc.branchName AS ofc_branchname,
    c.phone1 AS cust_phone1, c.phone2 AS cust_phone2,
    ss.sub_status,
    cc.touch_first_contact, cc.touch_source, cc.touch_medium,
    cc.cust_phone10 AS touch_phone,
    cc.ctm_call_id,
    CASE
      WHEN cc.touch_source IN ('Google Adwords','Ad Extension','Google Call Extension','call only','Google Call Asset',
										'Google Ads','Google Call Asset') 																	
																																						THEN 'Google Ads'
      WHEN cc.touch_source = 'wgl' 																											THEN 'WGL'
      WHEN cc.touch_source = 'website' 																									THEN 'Website'
      WHEN cc.touch_source = 'Direct' 																										THEN 'Direct'
      WHEN cc.touch_source IN ('GMB','GMB ','GMB - Glen Ellyn, IL 60137','Google My Business','GMB Post',
                            'GMB - Gurnee, IL 60031','North Chicago GMB','GMB - Brownsville',
                            'GMB - Newport News','GMB - Glen Ellyn, IL 60137',
									 'Google Business Profile - Website Visitor','Google Business Profile - Static Number') 												
									 																													THEN 'GBP'
      WHEN cc.touch_source IN ('facebook paid','General Meta Ads') 
																																						THEN 'Meta Ads'
      WHEN cc.touch_source IN ('Facebook video','Facebook Ads','facebook') 
																																						THEN 'Facebook Organic'
      WHEN cc.touch_source = 'Google LSA' 																								THEN 'Google LSA'
      WHEN cc.touch_source = 'Google organic' 																							THEN 'Google Organic'
      WHEN cc.touch_source = 'PestNet' 																									THEN 'PestNet'
      WHEN cc.touch_source = 'elocal' 																										THEN 'Elocal'
      WHEN cc.touch_source = 'Goodzer' 																									THEN 'Goodzer'
      WHEN cc.touch_source = 'email' 																										THEN 'Email'
      WHEN TRIM(cc.touch_source) = '' 																										THEN 'National Leads'
      WHEN cc.touch_source LIKE '%biz%' 																									THEN 'Local Biz'
      WHEN cc.touch_source IN ('bing','BING Paid','Bing Organic','Bing Call Extensions') 
																																						THEN 'Microsoft Ads'
      WHEN LOWER(cc.touch_source) LIKE '%service%direct%' 																			THEN 'Service Direct'
      WHEN cc.touch_source LIKE '%Google Ads Leadferno%' 																			THEN 'Google Ads'
      WHEN cc.touch_source LIKE '%Microsoft Ads Leadferno%' 																		THEN 'Microsoft Ads'
      WHEN cc.touch_source = 'Leadferno' 																									THEN 'Leadferno'
      WHEN cc.touch_source LIKE '%Google Ads Form%' 																					THEN 'Google Ads'
      WHEN cc.touch_source LIKE '%Microsoft Ads Form%' 																				THEN 'Microsoft Ads'
      WHEN cc.touch_source = 'Contact Form' 																								THEN 'Contact Form'
      WHEN cc.touch_source LIKE 'Form:%' 																									THEN cc.touch_source
      ELSE cc.touch_source
    END AS normalized_source,
    CASE
      WHEN cc.touch_source IN ('Google Adwords','Ad Extension','Google Call Extension',
										'call only','Google Call Asset','Google Ads') 
																																						THEN 'Paid'
      WHEN cc.touch_source = 'wgl' 																											THEN 'Paid'
      WHEN cc.touch_source = 'website' 																									THEN 'Non-Paid'
      WHEN cc.touch_source = 'Direct' 																										THEN 'Non-Paid'
      WHEN cc.touch_source IN ('GMB','GMB ','GMB - Glen Ellyn, IL 60137','Google My Business','GMB Post',
                            'GMB - Gurnee, IL 60031','North Chicago GMB','GMB - Brownsville',
                            'GMB - Newport News','GMB - Glen Ellyn, IL 60137') 
									 																													THEN 'Non-Paid'
      WHEN cc.touch_source IN ('facebook paid','General Meta Ads') 
																																						THEN 'Paid'
      WHEN cc.touch_source IN ('Facebook video','Facebook Ads','facebook') 
																																						THEN 'Paid'
      WHEN cc.touch_source = 'Google LSA' 																								THEN 'Paid'
      WHEN cc.touch_source = 'Google organic' 																							THEN 'Non-Paid'
      WHEN cc.touch_source = 'PestNet' 																									THEN 'Paid'
      WHEN cc.touch_source = 'Elocal' 																										THEN 'Paid'
      WHEN cc.touch_source = 'Goodzer' 																									THEN 'Paid'
      WHEN cc.touch_source = 'email' 																										THEN 'Non-Paid'
      WHEN TRIM(cc.touch_source) = '' 																										THEN 'Paid'
      WHEN cc.touch_source LIKE '%biz%' 																									THEN 'Paid'
      WHEN cc.touch_source IN ('Bing Paid','Bing Organic','Bing Call Extensions','Bing',
										'Local Biz Emails','LocalBizCslls') 
																																						THEN 'Paid'
      WHEN LOWER(cc.touch_source) LIKE '%service%direct%' 																			THEN 'Paid'
      WHEN cc.touch_source = 'Aragon' 																										THEN 'Paid'
      WHEN cc.touch_source = 'Consumer Affairs' 																						THEN 'Paid'
      WHEN cc.touch_source LIKE '%Google Ads Leadferno%' 																			THEN 'Paid'
      WHEN cc.touch_source LIKE '%Microsoft Ads Leadferno%' 																		THEN 'Paid'
      WHEN cc.touch_source = 'Leadferno' 																									THEN 'Non-Paid'
      WHEN cc.touch_source LIKE '%Google Ads Form%' 																					THEN 'Paid'
      WHEN cc.touch_source LIKE '%Microsoft Ads Form%' 																				THEN 'Paid'
      WHEN cc.touch_source = 'Contact Form' 																								THEN 'Non-Paid'
      WHEN cc.touch_source LIKE 'Form:%' 																									THEN 'Non-Paid'
      ELSE 'Non-Paid'
    END AS paid_type,
    cc.ctm_contact_number, cc.ctm_location, cc.ctm_referrer, cc.ctm_campaign,
    cc.wbf_referring_url, cc.wbf_source, cc.wbf_medium, cc.wbf_campaign,
    cc.wbf_utm_content, cc.wbf_utm_term, cc.wbf_form_name, cc.wbf_contact_name,
    cc.wbf_hearded_about, cc.wbf_referred_by, cc.wbf_current_customer, cc.wbf_commercial
  FROM candidate_subs cs
  JOIN sub_status ss ON ss.sub_id = cs.sub_id
  JOIN cust_contact cc ON cc.cust_customerid = cs.sub_customerid
  LEFT JOIN dwh_reportsdb.office ofc ON ofc.officeID = cs.sub_officeid
  LEFT JOIN dwh_reportsdb.customer c ON c.customerID = cs.sub_customerid
  WHERE cc.touch_first_contact < cs.sub_dateadded
)
SELECT * FROM claimed WHERE touch_first_contact >= '2026-01-01' AND touch_first_contact < CURDATE();