-- ========================================================
--  EMAIL ROI REPORT
-- ========================================================

DROP TEMPORARY TABLE IF EXISTS email_campaigns;
DROP TEMPORARY TABLE IF EXISTS email_counts;

CREATE TEMPORARY TABLE email_campaigns (
contact_email VARCHAR(100) NOT NULL,
campaign_name VARCHAR(250) NOT NULL,
campaign_date DATE NOT NULL,
PRIMARY KEY (contact_email, campaign_name)
);

-- Add data from a single csv file (should be a microsoft csv)
LOAD DATA LOCAL INFILE 'C:/Users/benjamin.bowen/Repos/Sql-Queries/Code/Recurring/email_campaigns.csv'
INTO TABLE email_campaigns
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES 
(contact_email, campaign_name, campaign_date);

CREATE TEMPORARY TABLE email_counts AS
SELECT contact_email, COUNT(*) AS times_contacted_by_email
FROM email_campaigns
GROUP BY contact_email;

-- /* This is just gathering data
SELECT 
	-- Email campaign info
	e.contact_email, e.campaign_name, e.campaign_date AS campaign_start_date, ec.times_contacted_by_email,
	
	-- First touch info
	r.touch_source, r.normalized_source, r.touch_first_contact, DATEDIFF(r.touch_first_contact, e.campaign_date) AS first_touch_after_email_date,
	
	-- New sale subscription info
	s.customerid, r.sub_customerid, s.subscriptionid, r.sub_id, c.email AS `Customer Email`, r.sub_dateadded, s.initialstatus, s.servicetype, s.contractvalue,
	case 
		when s.dateadded IS NULL 												  then 'No Subscription'
		when s.dateadded <= e.campaign_date 								  then 'Previous Subscription'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 1 WEEK) then 'Possible Sale 1 week'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 2 WEEK) then 'Possible Sale 2 weeks'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 3 WEEK) then 'Possible Sale 3 weeks'
		when s.dateadded < DATE_ADD(e.campaign_date, INTERVAL 4 WEEK) then 'Possible Sale 4 weeks'
		ELSE 'Sale After 4 Weeks'
	END AS `Subscription Classification`,
	
	-- Subscription cancellation info
	s.dateCancelled, DATEDIFF(s.dateCancelled, e.campaign_date) AS days_cancelled_after_email,
	case 
		when s.datecancelled IS NULL then 'Invalid cancel date'
		when DATEDIFF(s.datecancelled, e.campaign_date) > 0 then 'Cancelled after campaign'
		when DATEDIFF(s.datecancelled, e.campaign_date) < 0 then 'Cancelled before campaign'		
		when s.datecancelled = '0000-00-00 00:00:00' then 'Active'
		ELSE 'Not Cancelled'
	END AS `Cancellation_Classification`,
	
	CASE
		WHEN s.subscriptionID IS NULL THEN 'No Subscription'
    	WHEN s.dateCancelled IS NULL THEN 'Active'
    	when s.initialstatus = 1 then 'Quit Before Start'
    	WHEN s.dateCancelled >= e.campaign_date AND s.initialstatus != 1 THEN 'Quit Before Start After Campaign (Lost Revenue)'
	   WHEN s.dateCancelled >= e.campaign_date THEN 'Active at send (cancelled after)'
    	ELSE 'Cancelled before send'
	END AS cancel_status_at_email

FROM email_campaigns e
LEFT JOIN dwh_reportsdb.customer c ON c.email = e.contact_email
LEFT JOIN dwh_internetmarketingdb.roi_report r ON c.customerID = r.sub_customerid
LEFT JOIN dwh_reportsdb.subscription s 
	ON s.customerid = c.customerid 	 -- Provides all results that connect to an email (duplicates subscription rows where multiple subscriptions exist)
-- 	ON s.subscriptionid = r.sub_id -- alternate only provides results that have a touch, which removes legit email rows
LEFT JOIN email_counts ec ON ec.contact_email = e.contact_email; -- */
	
-- Drop tables
DROP TEMPORARY TABLE email_campaigns;
DROP TEMPORARY TABLE email_counts;
