-- ========================================================
--  EMAIL ROI REPORT
/* Affected rows: 3,373,926  Found rows: 909  Warnings: 10,579  Duration for 36 queries: 00:15:04.2 (+ 0.344 sec. network) */
-- ========================================================
USE dwh_reportsdb;

-- ========================================================
-- Import CSV data
-- Why multiple csv files?
-- 2026-08-04: campaigns.csv collapses the repeated campaign_name out of sends.csv into a foreign key.
-- 2026-08-05: emails.csv does the same for contact_email. LOAD DATA LOCAL is wire-bound
--   (~178 KB/s measured), so bytes on the wire ARE the runtime. 
--   Both strings live once in their own table and are rejoined here. Do not re-denormalize to one file.
--   All three files come from one run of build_email_campaigns.py and must be reloaded together -- the ids are only meaningful within a matched set.
-- ========================================================
-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
DROP TEMPORARY TABLE IF EXISTS email_campaigns;
CREATE TEMPORARY TABLE email_campaigns ( 
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS email_campaigns (
contact_email VARCHAR(100) NOT NULL,
campaign_name VARCHAR(250) NOT NULL,
campaign_date DATE NOT NULL,
opens INT UNSIGNED NULL, 
PRIMARY KEY (contact_email, campaign_name)
);

-- Load campaign data into table from csv
-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
DROP TEMPORARY TABLE IF EXISTS stg_campaigns;
CREATE TEMPORARY TABLE stg_campaigns ( 
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS stg_campaigns (
  campaign_id   INT UNSIGNED NOT NULL,
  campaign_name VARCHAR(250) NOT NULL,
  campaign_date DATE NOT NULL,
  PRIMARY KEY (campaign_id)
);

LOAD DATA LOCAL INFILE 'C:/Users/benjamin.bowen/Repos/Sql-Queries/Code/Recurring/campaigns.csv'
INTO TABLE stg_campaigns
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES 
(campaign_id, campaign_name, campaign_date);

-- Load send data into table from csv
-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
DROP TEMPORARY TABLE IF EXISTS stg_sends;
CREATE TEMPORARY TABLE stg_sends ( 
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS stg_sends (
  email_id 		 INT UNSIGNED NOT NULL,
  campaign_id   INT UNSIGNED NOT NULL,
  opens         INT UNSIGNED NULL
);

LOAD DATA LOCAL INFILE 'C:/Users/benjamin.bowen/Repos/Sql-Queries/Code/Recurring/sends.csv'
INTO TABLE stg_sends
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES 
(email_id, campaign_id, @opens)
-- 2026-08-04: opens goes through @opens, not straight into the column.
-- MySQL casts '1,120' to 1 with only a warning, and that 1 then passes the WHERE opens > 0 filter below as a legitimate single open. 
-- The regex forces anything non-numeric to NULL so it fails the filter instead of lying.
SET opens = IF(@opens REGEXP '^[0-9]+$', CAST(@opens AS UNSIGNED), NULL);

-- Load email data into table from csv
-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
DROP TEMPORARY TABLE IF EXISTS stg_emails;
CREATE TEMPORARY TABLE stg_emails ( 
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS stg_emails (
	email_id		  INT UNSIGNED NOT NULL,
	contact_email VARCHAR(100) NOT NULL,
	PRIMARY KEY (email_id)
);

LOAD DATA LOCAL INFILE 'C:/Users/benjamin.bowen/Repos/Sql-Queries/Code/Recurring/emails.csv'
INTO TABLE stg_emails
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES 
(email_id, contact_email);

-- Unite data from file by join
-- Toggle WHERE to see all emails and their open numbers
INSERT IGNORE INTO email_campaigns (contact_email, campaign_name, campaign_date, opens)
SELECT e.contact_email, c.campaign_name, c.campaign_date, s.opens
FROM stg_sends s
JOIN stg_campaigns c ON c.campaign_id = s.campaign_id
JOIN stg_emails e ON e.email_id = s.email_id

-- ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼ START TOGGLABLE WHERE ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
WHERE s.opens > 0 -- Remove this filter to see all emails and their open numbers
;
-- ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲ *END* TOGGLABLE WHERE ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

/* Every send resolves to an email and a campaign. Both should be 0.
SELECT
  (SELECT COUNT(*) FROM stg_sends s LEFT JOIN stg_emails    e ON e.email_id    = s.email_id    WHERE e.email_id    IS NULL) AS orphan_emails,
  (SELECT COUNT(*) FROM stg_sends s LEFT JOIN stg_campaigns c ON c.campaign_id = s.campaign_id WHERE c.campaign_id IS NULL) AS orphan_campaigns; -- */

-- 2026-7-30 -> This addition reduces execution time considerably by reducing the candidate customers
-- The index on email helps, but reducing the customer population helps more
-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
DROP TEMPORARY TABLE IF EXISTS tmp_customer;
CREATE TEMPORARY TABLE tmp_customer 
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS tmp_customer
(INDEX idx_email_customer (email, customerid))
AS SELECT email, customerid
FROM dwh_reportsdb.customer c 
WHERE c.email IN (SELECT DISTINCT contact_email FROM email_campaigns); -- This line is doing a LOT of work in a very small amount of time

-- This table allows us to count the number of times a particular email appears in all the campaign lists
-- 2026-08-04: built from stg_sends (UNFILTERED), not email_campaigns.
-- When email_campaigns is filtered to opens > 0, counting from it would redefine times_contacted_by_email from "times sent" to "times opened". 
-- Do not switch this to email_campaigns to save a scan.
-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
DROP TEMPORARY TABLE IF EXISTS email_counts;
CREATE TEMPORARY TABLE email_counts 
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS email_counts
(INDEX idx_email_campaignName (contact_email, campaign_name))
AS SELECT e.contact_email, c.campaign_name,
	COUNT(*) OVER (PARTITION BY e.contact_email) AS times_contacted_by_email,
	ROW_NUMBER() OVER (PARTITION BY e.contact_email ORDER BY c.campaign_date, c.campaign_name) AS times_emailed
FROM stg_sends s
JOIN stg_campaigns c ON c.campaign_id = s.campaign_id
JOIN stg_emails e ON e.email_id = s.email_id; -- 2026-08-05: v3 normalization. Join is for the NAME only.
                                              -- stg_sends stays the FROM table so the row set remains unfiltered.

-- ========================================================
-- Add customer data filtered by those that match the email list joined with five9 data
-- ========================================================
-- STEP 1: Create a temporary customer table that has phone1 and phone2 together
-- 2026-08-04: dedup collapses phone1 = phone2 on one customer, and repeat emails across customerids, rather than fanning out downstream.
-- 2026-08-05: the dedup moved from the PK (INSERT IGNORE) into the UNION, which killed ~10k per-row warnings. 
-- The PK is now a BACKSTOP, not the mechanism -- a plain INSERT means it THROWS instead of silently swallowing. 
-- That's intended: a dup surviving the UNION means an assumption broke and should be loud.
-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
DROP TEMPORARY TABLE IF EXISTS tmp_customer_phone;
CREATE TEMPORARY TABLE tmp_customer_phone ( 
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS tmp_customer_phone (
  customerid INT NOT NULL,
  phone VARCHAR(45)  NOT NULL,
  PRIMARY KEY (customerid, phone)   
);

-- 2026-08-05: This is the SECOND REFERENCE to email_campaigns for the UNION below.
-- A single statement cannot reference the same TEMPORARY table twice (MySQL 1137), and both arms need the email filter. 
-- Distinct emails only, with a PK, so the IN-subquery gets an index instead of scanning a heap.
-- Not a second campaign table -- do not delete as redundant.
-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
DROP TEMPORARY TABLE IF EXISTS email_campaigns_2;
CREATE TEMPORARY TABLE email_campaigns_2  
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS email_campaigns_2 
(PRIMARY KEY (contact_email, campaign_name))
AS SELECT * FROM email_campaigns;

-- 2026-08-05: UNION, not UNION ALL, and plain INSERT rather than INSERT IGNORE.
-- phone1 = phone2 on one customer, repeat emails across customerids
-- PK is the backstop if this ever stops deduping.
INSERT INTO tmp_customer_phone (customerid, phone)
SELECT c.customerid, c.phone1 
FROM dwh_reportsdb.customer c
WHERE c.email IN (SELECT contact_email FROM email_campaigns)
  AND c.phone1 IS NOT NULL AND c.phone1 <> '' AND LENGTH(c.phone1) = 10
UNION
SELECT c.customerid, c.phone2
FROM dwh_reportsdb.customer c
WHERE c.email IN (SELECT contact_email FROM email_campaigns_2)
  AND c.phone2 IS NOT NULL AND c.phone2 <> '' AND LENGTH(c.phone2) = 10;
  
-- STEP 2: create a temporary table that has the customer email, five9 timestamp, and five9 call type
-- 2026-08-05: CTAS then ALTER, not pre-indexed INSERT. 
-- Rows arrive in tmp_customer_phone order, which is random vs. the PK, so per-row clustered index maintenance across 1.8M rows cost ~15 min of a 17:51 run.
-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
DROP TEMPORARY TABLE IF EXISTS tmp_five9_customer;
CREATE TEMPORARY TABLE tmp_five9_customer AS 
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS tmp_five9_customer AS
SELECT f.callid, p.customerid, 
	f.`timestamp` 		AS five9_timestamp, 
	f.calltype 			AS five9_calltype, 
	f.customernumber 	AS five9_customernumber, 
	f.disposition 		AS five9_disposition
FROM tmp_customer_phone p
JOIN (
	SELECT callid, `timestamp`, calltype, customernumber, disposition
	FROM dwh_five9db.calls -- This table is enormous, so limiting it is essential to performance
	-- calls has no index on customernumber (verified via SHOW INDEX), so this range scan on ik_calls_timestamp is the only way to shrink it before the join.
	-- We don't know whether the calls table is live data, and filtering up to yesterday is good enough since all campaigns are in the past anyway
	WHERE `timestamp` >= '2026-01-01' AND `timestamp` < DATE_SUB(NOW(), INTERVAL 1 DAY)
) f ON f.customernumber = p.phone;

-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
-- Add index --> Include this in the toggle, because if we "create if exists" and existing table, then altering an existing index is an error
ALTER TABLE tmp_five9_customer ADD INDEX idx_email_ts (customerid, five9_timestamp); -- Belongs in the toggle

DROP TEMPORARY TABLE IF EXISTS tmp_campaign_five9;
-- This table will join the five9 information to the subscription information from
CREATE TEMPORARY TABLE tmp_campaign_five9 
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS tmp_campaign_five9
(PRIMARY KEY (subscriptionid))
AS
SELECT subscriptionid, five9_timestamp, five9_calltype, five9_customernumber, five9_disposition
FROM (
   SELECT s.subscriptionid, c.five9_timestamp, c.five9_calltype, c.five9_customernumber, c.five9_disposition,
      ROW_NUMBER() OVER (PARTITION BY s.subscriptionid ORDER BY c.five9_timestamp DESC) AS rn
   FROM dwh_reportsdb.subscription AS s
   LEFT JOIN tmp_five9_customer AS c
      ON c.customerid = s.customerid
      AND c.five9_timestamp < s.dateadded
   WHERE s.initialstatus = 1
      AND s.customerid IN (SELECT customerid FROM tmp_customer_phone)
) x
WHERE rn = 1;

-- ========================================================
-- CTEs
-- ========================================================
-- /* Toggleable CREATE --> Only untoggle for repeat queries per session. This toggle method will expose only one CREATE at a time
DROP TEMPORARY TABLE IF EXISTS tmp_allNumbers;
CREATE TEMPORARY TABLE tmp_allNumbers AS  
-- */ CREATE TEMPORARY TABLE IF NOT EXISTS tmp_allNumbers AS 
WITH campaigndata AS (
SELECT 
	-- Email campaign info
	e.*, ec.times_contacted_by_email, ec.times_emailed,

	-- five9 info
	f.five9_timestamp, DATEDIFF(f.five9_timestamp, s.dateadded) AS calldate_minus_subscriptiondate_days, f.five9_calltype, f.five9_customernumber, f.five9_disposition,
	
	/* First touch info
-- 	2026-08-04 -> First touch is unnecessary and just muddies the water
	r.touch_source, r.normalized_source, r.touch_first_contact, DATEDIFF(r.touch_first_contact, e.campaign_date) AS first_touch_after_email_date,
	DATEDIFF(s.dateadded, e.campaign_date) AS dateadded_after_email_date,	-- */
	
	-- New sale subscription info
	s.customerid, s.subscriptionid, s.dateadded, s.initialstatus, s.servicetype, s.contractvalue, r.sub_status,
	CASE 
		WHEN s.dateadded IS NULL OR s.dateadded = '0000-00-00 00:00:00' THEN 'No Subscription'
		WHEN s.dateadded <= e.campaign_date 								    THEN 'Previous Subscription'
		WHEN s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 1 WEEK)   THEN 'Possible Sale 1 week'
		WHEN s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 2 WEEK)   THEN 'Possible Sale 2 weeks'
		WHEN s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 3 WEEK)   THEN 'Possible Sale 3 weeks'
		WHEN s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 4 WEEK)   THEN 'Possible Sale 4 weeks'				
																							 ELSE 'Sale After 4 Weeks'
	END AS `Subscription Classification`,
	
	-- Subscription cancellation info
	s.dateCancelled, DATEDIFF(s.dateCancelled, e.campaign_date) AS days_cancelled_after_email,
	CASE 
		WHEN s.datecancelled IS NULL 								 THEN 'Invalid cancel date'
		WHEN DATEDIFF(s.datecancelled, e.campaign_date) > 0 THEN 'Cancelled after campaign'
		WHEN DATEDIFF(s.datecancelled, e.campaign_date) < 0 THEN 'Cancelled before campaign'		
		WHEN s.datecancelled = '0000-00-00 00:00:00'        THEN 'Active'
																			 ELSE 'Not Cancelled'
	END AS `Cancellation_Classification`,
	
	CASE
		WHEN s.subscriptionID IS NULL 														THEN 'No Subscription'
    	WHEN s.dateCancelled IS NULL OR s.datecancelled = '0000-00-00 00:00:00' THEN 'Active'
    	WHEN s.dateCancelled >= e.campaign_date AND s.initialstatus != 1 			THEN 'Quit Before Start After Campaign (Lost Revenue)'
    	WHEN s.initialstatus != 1 																THEN 'Quit Before Start'
	   WHEN s.dateCancelled >= e.campaign_date 											THEN 'Active at send (cancelled after)'
    																									ELSE 'Cancelled before send'
	END AS cancel_status_at_email

FROM email_campaigns e
LEFT JOIN tmp_customer c ON c.email = e.contact_email
LEFT JOIN dwh_reportsdb.subscription s 
	ON s.customerid = c.customerid -- Provides all results that connect to an email (duplicates subscription rows where multiple subscriptions exist)
	AND s.initialstatus = 1 		 -- Only includes actual subscriptions
LEFT JOIN tmp_campaign_five9 f
  ON f.subscriptionid = s.subscriptionid
LEFT JOIN dwh_internetmarketingdb.roi_master r ON r.sub_id = s.subscriptionid AND s.initialstatus = 1
LEFT JOIN email_counts ec ON ec.contact_email = e.contact_email AND ec.campaign_name = e.campaign_name -- The additional part in the on statement ensures uniqueness
-- 2026-08-04: DENSE_RANK, not ROW_NUMBER. [superseded -- see below]
-- 2026-08-05: What dr actually does: one subscription per (contact_email, campaign_date), the EARLIEST by dateadded. 
-- A contact with two subscriptions after the same send contributes ONE -- the second is dropped, not reattributed.
-- That is intentional: crediting one send with two sales overstates the campaign.
-- DENSE_RANK (not ROW_NUMBER) keeps same-date batch rows tied at 1 so first_campaign below picks the batch; 
-- 	same-date "campaigns" are just batches of one real campaign, so which batch wins is arbitrary by design.
), ranking AS (
	SELECT *, DENSE_RANK() OVER (PARTITION BY contact_email, campaign_date ORDER BY dateadded) AS dr
	FROM campaigndata
	-- 2026-08-05: PERMANENT attribution floor. Not a display filter, do not toggle.
	-- Runs before the DENSE_RANK above, so it defines the candidate set that dr ranks over.
	-- Excludes NULL/zero dateadded (customer record, not a sale) and dateadded <= campaign_date ('Previous Subscription'). 
	-- Both sort ahead of real sales under ORDER BY dateadded ASC and would take dr=1, suppressing the genuine attributed sale in that partition.
	WHERE dateadded > campaign_date
	
-- ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼ START TOGGLABLE WHERE ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
-- 	/* Remove this WHERE to see all subscriptions that occurred after the campaign
-- 	Or toggle any or each of the individual classifications
--    There are many subscriptions that are irrelevant to campaigns because they started long after the email was sent
	AND `Subscription Classification` IN (
		'Possible Sale 1 week'
		, 'Possible Sale 2 weeks'
		, 'Possible Sale 3 weeks'
-- 		, 'Possible Sale 4 weeks'
	) -- */
-- ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲ *END* TOGGLABLE WHERE ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
 
-- Eliminate cross-campaign duplicate subscriptions: subscriptions are collapsed into single-campaign attribution
), first_campaign AS ( 
SELECT *, ROW_NUMBER() OVER (PARTITION BY subscriptionid ORDER BY campaign_date, campaign_name) AS rn
FROM ranking
WHERE dr = 1
)

SELECT * FROM first_campaign
WHERE rn = 1;


-- /* Prod select
SELECT * FROM tmp_allNumbers; -- */

-- ========================================================
-- Aggregates, testing only
-- ========================================================
/* OVERALL
SELECT
	`Subscription Classification`,
	COUNT(*)                                                     	  AS sales,
	CONCAT('$',FORMAT(SUM(contractvalue),2))								  AS total_value_formatted,
	SUM(contractvalue)			                                      AS total_value_number,
	SUM(cancel_status_at_email = 'Active at send (cancelled after)') AS cancelled_after_email
FROM tmp_allNumbers
WHERE initialstatus = 1
GROUP BY `Subscription Classification`
ORDER BY `Subscription Classification`
; -- */

/* BY CAMPAIGN
SELECT
	campaign_name,
	`Subscription Classification`,
	COUNT(*)                                                     	  AS sales,
	CONCAT('$',FORMAT(SUM(contractvalue),2))								  AS total_value_formatted,
	SUM(contractvalue)			                                      AS total_value_number,
	SUM(cancel_status_at_email = 'Active at send (cancelled after)') AS cancelled_after_email
FROM tmp_allNumbers
WHERE initialstatus = 1
GROUP BY campaign_name, `Subscription Classification`
ORDER BY `Subscription Classification`, campaign_name
;
-- */

/* BY CAMPAIGN AND SERVICE TYPE
SELECT
	campaign_name,
	`Subscription Classification`,
	`servicetype`,
	COUNT(*)                                                     	  AS sales,
	CONCAT('$',FORMAT(SUM(contractvalue),2))								  AS total_value_formatted,
	SUM(contractvalue)			                                      AS total_value_number,
	SUM(cancel_status_at_email = 'Active at send (cancelled after)') AS cancelled_after_email
FROM tmp_allNumbers
WHERE initialstatus = 1
GROUP BY campaign_name, `Subscription Classification`, `servicetype`
ORDER BY `Subscription Classification`, campaign_name, `servicetype`
;
-- */
	
-- /* Drop tables
DROP TEMPORARY TABLE email_campaigns;
DROP TEMPORARY TABLE email_campaigns_2;
DROP TEMPORARY TABLE stg_campaigns;
DROP TEMPORARY TABLE stg_sends;
DROP TEMPORARY TABLE stg_emails;
DROP TEMPORARY TABLE tmp_customer;
DROP TEMPORARY TABLE email_counts;
DROP TEMPORARY TABLE tmp_customer_phone;
DROP TEMPORARY TABLE tmp_five9_customer;
DROP TEMPORARY TABLE tmp_campaign_five9;
DROP TEMPORARY TABLE tmp_allNumbers;
-- */

























