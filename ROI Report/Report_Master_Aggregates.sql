-- Roi Master investigation
SELECT
  YEAR(touch_first_contact)            AS touch_year,
--   MONTH(touch_first_contact)           AS touch_month,
  sub_status,
  COUNT(*)                             AS sales,
  FORMAT(SUM(sub_contractvalue), 2)    AS contract_value -- This is here for viewing convenience
FROM dwh_internetmarketingdb.roi_master
GROUP BY 
	touch_year, 
-- 	touch_month, 
	sub_status
ORDER BY 
	touch_year, 
-- 	touch_month, 
	sub_status; 
	
-- Roi report investigation
SELECT
  YEAR(touch_first_contact)            AS touch_year,
--   MONTH(touch_first_contact)           AS touch_month,
  sub_status,
  COUNT(*)                             AS sales,
  FORMAT(SUM(sub_contractvalue), 2)    AS contract_value -- This is here for viewing convenience
FROM dwh_internetmarketingdb.roi_report
GROUP BY 
	touch_year, 
-- 	touch_month, 
	sub_status
ORDER BY 
	touch_year, 
-- 	touch_month, 
	sub_status; 
	