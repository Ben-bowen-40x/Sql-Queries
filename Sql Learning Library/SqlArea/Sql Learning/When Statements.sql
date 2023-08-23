SELECT

    ## Cleaner months easier to read months using calendar table 
    cal.month_name,

    # Total Calls  for 2022/2023
    COUNT(IF(cal.year=2022, c.callID, NULL)) AS CALLS_2022,
    COUNT(IF(cal.year=2022 AND (c.disposition LIKE '%spam%' OR c.disposition LIKE '%scam%'), c.callID, NULL)) AS SPAM_CALLS_2022,
    COUNT(IF(cal.year=2023, c.callID, NULL)) AS CALLS_2023,
    COUNT(IF(cal.year=2023 AND (c.disposition LIKE '%spam%' OR c.disposition LIKE '%scam%'), c.callID, NULL)) as SPAM_CALLS_2023

## Use Calls as your base not call stats     
FROM dwh_five9db.calls c

##don't need this for the query 
## INNER JOIN dwh_five9db.calls c ON cs.callID = cs.callID

## Added this to clean up month grouping
LEFT JOIN dwh_reportsdb.calendar cal ON cal.db_date = date(c.timestamp)
WHERE 
  c.campaign LIKE 'Abandon Recall'
  AND c.callCategory LIKE 'Outbound'

GROUP BY cal.month
ORDER BY cal.month asc