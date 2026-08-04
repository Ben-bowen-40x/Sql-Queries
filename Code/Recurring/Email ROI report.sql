-- ========================================================
--  EMAIL ROI REPORT
/* Affected rows: 3,373,926  Found rows: 909  Warnings: 10,579  Duration for 36 queries: 00:15:04.2 (+ 0.344 sec. network) */
-- ========================================================
USE dwh_five9db;
USE dwh_reportsdb;

DROP TEMPORARY TABLE IF EXISTS email_campaigns;
DROP TEMPORARY TABLE IF EXISTS stg_campaigns;
DROP TEMPORARY TABLE IF EXISTS stg_sends;
DROP TEMPORARY TABLE IF EXISTS tmp_customer;
DROP TEMPORARY TABLE IF EXISTS email_counts;
DROP TEMPORARY TABLE IF EXISTS tmp_customer_phone;
DROP TEMPORARY TABLE IF EXISTS tmp_email_calls;
DROP TEMPORARY TABLE IF EXISTS tmp_campaign_five9;

-- ========================================================
-- Import CSV data
-- Why two csv files? 
-- 2026-08-04:: campaigns.csv collapses a huge number of duplicated rows in send.csv into a foreign key
-- ========================================================
CREATE TEMPORARY TABLE email_campaigns (
contact_email VARCHAR(100) NOT NULL,
campaign_name VARCHAR(250) NOT NULL,
campaign_date DATE NOT NULL,
opens INT UNSIGNED NULL, 
PRIMARY KEY (contact_email, campaign_name)
);

-- Load campaign data into table from csv
CREATE TEMPORARY TABLE stg_campaigns (
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
CREATE TEMPORARY TABLE stg_sends (
  contact_email VARCHAR(100) NOT NULL,
  campaign_id   INT UNSIGNED NOT NULL,
  opens         INT UNSIGNED NULL
);

LOAD DATA LOCAL INFILE 'C:/Users/benjamin.bowen/Repos/Sql-Queries/Code/Recurring/sends.csv'
INTO TABLE stg_sends
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES 
(contact_email, campaign_id, @opens)
-- 2026-08-04: opens goes through @opens, not straight into the column.
-- MySQL casts '1,120' to 1 with only a warning, and that 1 then passes the WHERE opens > 0 filter below as a legitimate single open. 
-- The regex forces anything non-numeric to NULL so it fails the filter instead of lying.
SET opens = IF(@opens REGEXP '^[0-9]+$', CAST(@opens AS UNSIGNED), NULL);

-- ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼ START TOGGLABLE WHERE ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
-- Unite data from file by join
-- Toggle WHERE to see all emails and their open numbers
INSERT INTO email_campaigns (contact_email, campaign_name, campaign_date, opens)
SELECT s.contact_email, c.campaign_name, c.campaign_date, s.opens
FROM stg_sends s
JOIN stg_campaigns c ON c.campaign_id = s.campaign_id
-- WHERE s.opens > 0 -- Remove this to see all emails and their open numbers
;
-- ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲ *END* TOGGLABLE WHERE ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

-- 2026-7-30 -> This addition reduces execution time considerably by reducing the candidate customers
-- The index on email helps, but reducing the customer population helps more
CREATE TEMPORARY TABLE tmp_customer
(INDEX idx_email_customer (email, customerid))
AS SELECT email, customerid
FROM dwh_reportsdb.customer c 
WHERE c.email IN (SELECT DISTINCT contact_email FROM email_campaigns); -- This line is doing a LOT of work in a very small amount of time

-- This table allows us to count the number of times a particular email appears in all the campaign lists
-- 2026-08-04: built from stg_sends (UNFILTERED), not email_campaigns.
-- when email_campaigns is filtered to opens > 0, counting from it would redefine times_contacted_by_email from "times sent" to "times opened". 
-- Do not switch this to email_campaigns to save a scan.
CREATE TEMPORARY TABLE email_counts
(INDEX idx_email_campaignName (contact_email, campaign_name))
AS SELECT s.contact_email, c.campaign_name,
	COUNT(*) OVER (PARTITION BY s.contact_email) AS times_contacted_by_email,
	ROW_NUMBER() OVER (PARTITION BY s.contact_email ORDER BY c.campaign_date, c.campaign_name) AS times_emailed
FROM stg_sends s
JOIN stg_campaigns c ON c.campaign_id = s.campaign_id;

-- ========================================================
-- Add customer data filtered by those that match the email list joined with five9 data
-- ========================================================
-- STEP 1: Create a temporary customer table that has phone1 and phone2 together
-- 2026-08-04: PK is the dedup. phone1 = phone2 on the same customer, and repeat emails across customerids, both collapse here rather than fanning out downstream.
CREATE TEMPORARY TABLE tmp_customer_phone (
  email VARCHAR(100) NOT NULL,
  phone VARCHAR(20)  NOT NULL,
  PRIMARY KEY (email, phone)   
);

-- Insert ignore prevents the same email, phone combo from throwing on insert
-- Insert phone1 into the customer table
INSERT IGNORE INTO tmp_customer_phone (email, phone)
SELECT c.email, c.phone1 FROM dwh_reportsdb.customer c
WHERE c.email IN (SELECT contact_email FROM email_campaigns)
  AND c.phone1 IS NOT NULL AND c.phone1 <> '' AND LENGTH(c.phone1) = 10;

-- Insert phone2 into the customer table
INSERT IGNORE INTO tmp_customer_phone (email, phone)
SELECT c.email, c.phone2 FROM dwh_reportsdb.customer c
WHERE c.email IN (SELECT contact_email FROM email_campaigns)
  AND c.phone2 IS NOT NULL AND c.phone2 <> '' AND LENGTH(c.phone2) = 10;
  
-- STEP 2: create a temporary table that has the customer email, five9 timestamp, and five9 call type
-- 2026-08-04: PK on callid, not phone. Guards both the dnis = customernumber row-level dup AND the case where a call matches phone1 on dnis and phone2 on customernumber — two real matches, one actual call.
CREATE TEMPORARY TABLE tmp_email_calls (
  callid BIGINT NOT NULL,
  email VARCHAR(100) NOT NULL,
  five9_timestamp DATETIME NOT NULL,
  five9_calltype VARCHAR(50) NULL,
  primary key (email, callid),
  INDEX idx_email_ts (email, five9_timestamp)
);

-- 2026-08-04: single arm on customernumber only. dnis is the *dialed* number:
-- customer's number on outbound, company's tracking number on inbound.
-- customernumber is the DBA's derived field that resolves to the customer in both directions, so it's a superset of what a dnis join can find. 
-- Joining dnis additionally would false-attribute inbound calls to any customer who has a company number on file. Do not re-add the dnis arm.
INSERT IGNORE INTO tmp_email_calls (callid, email, five9_timestamp, five9_calltype)
SELECT f.callid, p.email, f.`timestamp`, f.calltype
FROM tmp_customer_phone p
JOIN dwh_five9db.calls f ON f.customernumber = p.phone;

CREATE TEMPORARY TABLE tmp_campaign_five9
(PRIMARY KEY (contact_email, campaign_name))
AS
SELECT contact_email, campaign_name, five9_timestamp, five9_calltype
FROM (
  SELECT e.contact_email, e.campaign_name, c.five9_timestamp, c.five9_calltype,
  	ROW_NUMBER() OVER (PARTITION BY e.contact_email, e.campaign_name ORDER BY c.five9_timestamp DESC) AS rn
  FROM email_campaigns e
  LEFT JOIN tmp_email_calls c
    ON c.email = e.contact_email
   AND c.five9_timestamp < e.campaign_date
) x
WHERE rn = 1;

SELECT COUNT(*) AS rows_total,
       SUM(five9_timestamp IS NULL) AS no_prior_call
FROM tmp_campaign_five9;

-- ========================================================
-- CTEs
-- ========================================================
WITH campaigndata AS (
SELECT 
	-- Email campaign info
	e.*, ec.times_contacted_by_email, ec.times_emailed,

	-- five9 info
	f.five9_timestamp, f.five9_calltype,
	
	/* First touch info
-- 	2026-08-04 -> First touch is unnecessary and just muddies the water
	r.touch_source, r.normalized_source, r.touch_first_contact, DATEDIFF(r.touch_first_contact, e.campaign_date) AS first_touch_after_email_date,
	DATEDIFF(s.dateadded, e.campaign_date) AS dateadded_after_email_date,	-- */
	
	-- New sale subscription info
	s.customerid, s.subscriptionid, s.dateadded, s.initialstatus, s.servicetype, s.contractvalue, r.sub_status,
	case 
		when s.dateadded IS NULL OR s.dateadded = '0000-00-00 00:00:00' then 'No Subscription'
		when s.dateadded <= e.campaign_date 								    then 'Previous Subscription'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 1 WEEK)   then 'Possible Sale 1 week'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 2 WEEK)   then 'Possible Sale 2 weeks'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 3 WEEK)   then 'Possible Sale 3 weeks'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 4 WEEK)   then 'Possible Sale 4 weeks'
																							 ELSE 'Sale After 4 Weeks'
	END AS `Subscription Classification`,
	
	-- Subscription cancellation info
	s.dateCancelled, DATEDIFF(s.dateCancelled, e.campaign_date) AS days_cancelled_after_email,
	case 
		when s.datecancelled IS NULL 								 then 'Invalid cancel date'
		when DATEDIFF(s.datecancelled, e.campaign_date) > 0 then 'Cancelled after campaign'
		when DATEDIFF(s.datecancelled, e.campaign_date) < 0 then 'Cancelled before campaign'		
		when s.datecancelled = '0000-00-00 00:00:00'        then 'Active'
																			 ELSE 'Not Cancelled'
	END AS `Cancellation_Classification`,
	
	CASE
		WHEN s.subscriptionID IS NULL 														then 'No Subscription'
    	WHEN s.dateCancelled IS NULL OR s.datecancelled = '0000-00-00 00:00:00' then 'Active'
    	WHEN s.dateCancelled >= e.campaign_date AND s.initialstatus != 1 			then 'Quit Before Start After Campaign (Lost Revenue)'
    	WHEN s.initialstatus != 1 																then 'Quit Before Start'
	   WHEN s.dateCancelled >= e.campaign_date 											then 'Active at send (cancelled after)'
    																									ELSE 'Cancelled before send'
	END AS cancel_status_at_email

FROM email_campaigns e
LEFT JOIN tmp_campaign_five9 f
  ON f.contact_email = e.contact_email
 AND f.campaign_name = e.campaign_name
LEFT JOIN tmp_customer c ON c.email = e.contact_email
LEFT JOIN dwh_reportsdb.subscription s 
	ON s.customerid = c.customerid -- Provides all results that connect to an email (duplicates subscription rows where multiple subscriptions exist)
	AND s.initialstatus = 1 		 -- Only includes actual subscriptions
LEFT JOIN dwh_internetmarketingdb.roi_master r ON r.sub_id = s.subscriptionid AND s.initialstatus = 1
LEFT JOIN email_counts ec ON ec.contact_email = e.contact_email AND ec.campaign_name = e.campaign_name -- The additional part in the on statement ensures uniqueness
-- 2026-08-04: DENSE_RANK, not ROW_NUMBER. Two campaigns on the same date to the same contact produce two rows for the SAME subscription with identical dateadded. 
-- DENSE_RANK ties them at rank 1 so both survive, and first_campaign picks the earliest campaign. 
-- ROW_NUMBER would drop one arbitrarily here and break same-date attribution.
), ranking AS (
	SELECT *, DENSE_RANK() OVER (PARTITION BY contact_email, campaign_date ORDER BY dateadded) AS dr
	FROM campaigndata

-- ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼ START TOGGLABLE WHERE ▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼▼
-- 	/* Remove this WHERE to see all subscriptions that occurred after the campaign
-- 	Or toggle any or each of the individual classifications
--    There are many subscriptions that are irrelevant to campaigns because they started long after the email was sent
	WHERE `Subscription Classification` IN (
		'Possible Sale 1 week'
		, 'Possible Sale 2 weeks'
		, 'Possible Sale 3 weeks'
		-- , 'Possible Sale 4 weeks'
	) -- */
-- ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲ *END* TOGGLABLE WHERE ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲
 
-- /* This added minutes to the query execution time
-- This is here to eliminate cross-campaign duplicate subscriptions: subscriptions are collapsed into single-campaign attribution
), first_campaign AS ( 
SELECT *, ROW_NUMBER() OVER (PARTITION BY subscriptionid ORDER BY campaign_date, campaign_name) AS rn
FROM ranking
WHERE dr = 1
) # */

/* Prod select
SELECT * FROM first_campaign
WHERE rn = 1; -- */

-- /* Aggregates, testing only
SELECT
	`Subscription Classification`,
	COUNT(*)                                                     	  AS subs,
	SUM(contractvalue)                                           	  AS total_value,
	SUM(cancel_status_at_email = 'Cancelled before send')        	  AS cancelled_pre,
	SUM(cancel_status_at_email = 'Active at send (cancelled after)') AS cancelled_post
FROM first_campaign
WHERE rn = 1 AND initialstatus = 1
GROUP BY `Subscription Classification`
ORDER BY `Subscription Classification`
; -- */
	
	
-- Drop tables
DROP TEMPORARY TABLE email_campaigns;
DROP TEMPORARY TABLE stg_campaigns;
DROP TEMPORARY TABLE stg_sends;
DROP TEMPORARY TABLE tmp_customer;
DROP TEMPORARY TABLE email_counts;
DROP TEMPORARY TABLE tmp_customer_phone;
DROP TEMPORARY TABLE tmp_email_calls;
DROP TEMPORARY TABLE tmp_campaign_five9;
