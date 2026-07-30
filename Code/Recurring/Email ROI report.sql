-- ========================================================
--  EMAIL ROI REPORT
-- ========================================================

DROP TEMPORARY TABLE IF EXISTS email_campaigns;
DROP TEMPORARY TABLE IF EXISTS email_counts;
DROP TEMPORARY TABLE IF EXISTS tmp_customer;

-- This will be populated by a csv file
CREATE TEMPORARY TABLE email_campaigns (
contact_email VARCHAR(100) NOT NULL,
campaign_name VARCHAR(250) NOT NULL,
campaign_date DATE NOT NULL,
PRIMARY KEY (contact_email, campaign_name),
INDEX indx_contact_email (contact_email)
);

-- Add data from a single csv file (should be a microsoft csv)
LOAD DATA LOCAL INFILE 'C:/Users/benjamin.bowen/Repos/Sql-Queries/Code/Recurring/email_campaigns.csv'
INTO TABLE email_campaigns
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES 
(contact_email, campaign_name, campaign_date);

-- 2026-7-30 10.30a -> This addition reduces total execution time from ~8+ minutes to ~20 seconds
-- The index on email helps, but reducing the customer population helps more
CREATE TEMPORARY TABLE tmp_customer
(INDEX idx_customer_email (email, customerid))
AS SELECT email, customerid
FROM dwh_reportsdb.customer c 
WHERE c.email IN (SELECT contact_email FROM email_campaigns); -- This line is doing a LOT of work in a very small amount of time

-- Temporary table allows us to count the number of times a particular email appears in all the campaign lists,
-- * without repeating the first temporary table
CREATE TEMPORARY TABLE email_counts AS
SELECT contact_email, COUNT(*) AS times_contacted_by_email
FROM email_campaigns
GROUP BY contact_email;

-- Gather data
WITH campaigndata AS (
SELECT 
	-- Email campaign info
	e.campaign_name, e.campaign_date AS campaign_start_date, e.contact_email, ec.times_contacted_by_email,
	
	-- First touch info
	r.touch_source, r.normalized_source, r.touch_first_contact, DATEDIFF(r.touch_first_contact, e.campaign_date) AS first_touch_after_email_date,
	DATEDIFF(s.dateadded, e.campaign_date) AS dateadded_after_email_date,	
	
	-- New sale subscription info
	s.customerid, s.subscriptionid, s.dateadded, s.initialstatus, s.servicetype, s.contractvalue, r.sub_status,
	case 
		when s.dateadded IS NULL OR s.dateadded = '000-00-00 00:00:00' then 'No Subscription'
		when s.dateadded <= e.campaign_date 								   then 'Previous Subscription'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 1 WEEK)  then 'Possible Sale 1 week'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 2 WEEK)  then 'Possible Sale 2 weeks'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 3 WEEK)  then 'Possible Sale 3 weeks'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 4 WEEK)  then 'Possible Sale 4 weeks'
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
    	when s.initialstatus != 1 																then 'Quit Before Start'
    	WHEN s.dateCancelled >= e.campaign_date AND s.initialstatus != 1 			then 'Quit Before Start After Campaign (Lost Revenue)'
	   WHEN s.dateCancelled >= e.campaign_date 											then 'Active at send (cancelled after)'
    																									ELSE 'Cancelled before send'
	END AS cancel_status_at_email

FROM email_campaigns e
LEFT JOIN tmp_customer c ON c.email = e.contact_email
LEFT JOIN dwh_reportsdb.subscription s 
	ON s.customerid = c.customerid 	 -- Provides all results that connect to an email (duplicates subscription rows where multiple subscriptions exist)
LEFT JOIN dwh_internetmarketingdb.roi_master r ON r.sub_id = s.subscriptionid
LEFT JOIN email_counts ec ON ec.contact_email = e.contact_email
), ranking AS (
	SELECT *, DENSE_RANK() OVER (PARTITION BY contact_email, campaign_start_date ORDER BY dateadded) AS dr
	FROM campaigndata
-- 	/* Remove this WHERE to see all subscriptions that occurred after the campaign
--     There are many subscriptions that are irrelevant to campaigns because they started long after the email was sent
	WHERE `Subscription Classification` IN (
		'Possible Sale 1 week'
-- 		'Possible Sale 2 weeks',
-- 		'Possible Sale 3 weeks',
-- 		'Possible Sale 4 weeks'
	) AND initialstatus = 1 
-- */
) 
-- This added ~1 min 20s or more to the query execution time
-- This is here to eliminate cross-campaign duplicate subscriptions:
-- * subscriptions are collapsed into single-campaign attribution (theoretically)
, first_campaign AS ( 
SELECT *, ROW_NUMBER() OVER (PARTITION BY subscriptionid ORDER BY campaign_start_date, campaign_name) AS rn
FROM ranking
WHERE dr = 1
)

-- /* Prod select
SELECT * FROM first_campaign
WHERE rn = 1; -- */

/* Aggregate, testing only
SELECT 
	campaign_name, 
	COUNT(DISTINCT contact_email) AS total_conversion_emails,
	
-- /* Service type groupings, can be omitted 
	servicetype,
	COUNT(servicetype) AS count_servicetype,
	FORMAT(AVG(contractvalue),2) AS average_value, -- */
	
	/*
	FORMAT(SUM(contractvalue),2) AS total_value
FROM first_campaign
WHERE rn = 1
GROUP BY campaign_name
, servicetype
ORDER BY campaign_name asc
; -- */
	
-- Drop tables
DROP TEMPORARY TABLE email_campaigns;
DROP TEMPORARY TABLE email_counts;
DROP TEMPORARY TABLE tmp_customer;
