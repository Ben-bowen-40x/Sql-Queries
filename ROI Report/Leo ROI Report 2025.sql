WITH cm AS (
  /* Normalize source ONCE and assign paidType ONCE */
  /*Lead and source data from CTM*/
  SELECT
  /* Add a distinct to filter results before processing*/
      contact_number_clean,
      datecontacted,
--       /* Normalized Source
      CASE
        WHEN source IN ('Google Adwords','Ad Extension','Google Call Extension',
		  					'call only','Google Ads','Google Call Asset')
		  																																		THEN 'Google Ads'
        WHEN source = 'wgl' 																											THEN 'WGL'
        WHEN source = 'website' 																										THEN 'Website'
        WHEN source = 'Direct' 																										THEN 'Direct'
        WHEN source IN ('GMB','GMB ','GMB - Glen Ellyn, IL 60137','Google My Business','GMB Post',
                        'GMB - Gurnee, IL 60031','North Chicago GMB','GMB - Brownsville',
                        'GMB - Newport News','GMB - Glen Ellyn, IL 60137','GMB -  Glen Ellyn, IL 60137',
								'Google Business Profile - Static Number','Google Business Profile - Static Number') 
																																				THEN 'GBP'
        WHEN source IN ('facebook paid','General Meta Ads') 																THEN 'Meta Ads'
        WHEN source IN ('Facebook video','Facebook Ads','facebook') 														THEN 'Facebook Organic'
        WHEN source = 'Google LSA' 																									THEN 'Google LSA'
        WHEN source = 'Google organic' 																							THEN 'Google Organic'
        WHEN source = 'PestNet' 																										THEN 'PestNet'
        WHEN source = 'elocal' 																										THEN 'Elocal'
        WHEN source = 'Goodzer' 																										THEN 'Goodzer'
        WHEN source = 'email' 																										THEN 'Email'
        WHEN TRIM(SOURCE) = '' 																										THEN 'National Leads' -- Ask Leo about this
        WHEN source LIKE '%biz%' 																									THEN 'Local Biz'
        WHEN source IN ('bing', 'BING Paid','Bing Organic','Bing Call Extensions') 
		  																																		THEN 'Microsoft Ads'
        WHEN LOWER(source) LIKE '%service%direct%' 																			THEN 'Service Direct'
        ELSE source
      END AS SOURCE,#*/
--       Your Paid / Non-Paid mapping
      CASE
        WHEN source IN ('Google Adwords','Ad Extension','Google Call Extension','call only','Google Ads') 	THEN 'Paid'
        WHEN source = 'wgl' 																											THEN 'Paid'
        WHEN source = 'website' 																										THEN 'Non-Paid'
        WHEN source = 'Direct' 																										THEN 'Non-Paid'
        WHEN source IN ('GMB','GMB ','GMB - Glen Ellyn, IL 60137','Google My Business','GMB Post',
                        'GMB - Gurnee, IL 60031','North Chicago GMB','GMB - Brownsville',
                        'GMB - Newport News','GMB - Glen Ellyn, IL 60137') 
																																				THEN 'Non-Paid'
        WHEN source IN ('facebook paid','General Meta Ads')
		  																																		THEN 'Paid'
        WHEN source IN ('Facebook video','Facebook Ads','facebook') 
		  																																		THEN 'Paid'
        WHEN source = 'Google LSA' 																									THEN 'Paid'
        WHEN source = 'Google organic' 																							THEN 'Non-Paid'
        WHEN source = 'PestNet' 																										THEN 'Paid'
        WHEN source = 'Elocal' 																										THEN 'Paid'
        WHEN source = 'Goodzer' 																										THEN 'Paid'
        WHEN source = 'email' 																										THEN 'Non-Paid'
        WHEN TRIM(SOURCE) = '' 																										THEN 'Paid'
        WHEN source LIKE '%biz%' 																									THEN 'Paid'
        WHEN source IN ('Bing Paid','Bing Organic','Bing Call Extensions', 'Bing', 'Local Biz Emails', 
		  						'LocalBizCslls') 
		  																																		THEN 'Paid'
        WHEN LOWER(source) LIKE '%service%direct%' 																			THEN 'Paid'
         WHEN source = 'Aragon' 																										THEN 'Paid'
          WHEN source = 'Consumer Affairs' 																						THEN 'Paid'
        ELSE 'Non-Paid' -- Change to Not-Determined
      END AS paidType
  FROM dwh_ctmdb.calls
  WHERE sale_billable = 'billable'
    AND YEAR(datecontacted) >= 2021
),

/* Subscriptions matched to calls */
subs AS (
  SELECT DISTINCT
      cm.Source,
      cm.paidType,
      s.subscriptionID,
      s.contractValue,
      s.initialStatus,
      o.branchname,
      DATE(s.dateadded) AS activity_date, YEAR(s.dateadded) AS `year`, MONTH(s.dateadded) AS `month`
  FROM cm
  LEFT JOIN dwh_reportsdb.customer c1 ON cm.contact_number_clean = c1.phone1
  LEFT JOIN dwh_reportsdb.customer c2 ON cm.contact_number_clean = c2.phone2
  LEFT JOIN dwh_reportsdb.subscription s
    ON s.customerID = COALESCE(c1.customerID, c2.customerID)
   AND s.initialStatus = 1
   AND YEAR(s.dateadded) >= 2021
   AND s.source LIKE '%internet%'
  LEFT JOIN dwh_reportsdb.office o ON s.officeID = o.officeid
  WHERE s.subscriptionID IS NOT NULL
    AND o.branchname NOT IN ( -- Filter out FDS
      'Pensacola - FL','Portland - ME','South Bend - IN','Springfield - MA',
      'Iowa City - IA','Portland - Maine','Davenport - IA','Evansville - IN',
      'Kennewick - WA','Sioux Falls - SD','Burlington - VT','Reno - NV','Spokane - WA'
    )
)
/*Stephen and Hayden analysis stopped here*/
--

-- /*
SELECT *
FROM (
  # ---------- lead_daily ---------- 
  SELECT
      Source,
      DATE(datecontacted) AS activity_date, YEAR(datecontacted) AS `year`, MONTH(datecontacted) AS `month`, 
      1 AS total_leads,
      CAST(0 AS DECIMAL(18,2)) AS total_contract_value,
      'N/A' AS branchname,
      NULL AS initialStatus,
      paidType
  FROM cm

  UNION ALL

  # ---------- value_daily ----------
  SELECT
      Source,
      activity_date, `year`, `month`,
      0 AS total_leads,
      SUM(contractValue) AS total_contract_value,
      branchname,
      MAX(initialStatus) AS initialStatus,
      MAX(paidType) AS paidType
  FROM subs
  GROUP BY Source, activity_date, branchname

  UNION ALL

  # ---------- commercial_daily (added back) ---------- 
  SELECT
      'Commercial' AS Source,
      DATE(s.dateadded) AS activity_date, YEAR(s.dateadded) AS `year`, MONTH(s.dateadded) AS `month`,
      0 AS total_leads,
      SUM(s.contractValue) AS total_contract_value,
      'N/A' AS branchname,
      MAX(s.initialStatus) AS initialStatus,
      'Non-Paid' AS paidType   -- change to 'Paid' if you consider Commercial paid traffic
  FROM dwh_reportsdb.subscription s
  WHERE s.commercialaccount = 1
    AND s.initialStatus = 1
    AND s.source LIKE '%internet%'
    AND YEAR(s.dateadded) >= 2021
  GROUP BY DATE(s.dateadded)
) AS final_daily
ORDER BY activity_date, Source;