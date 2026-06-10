SELECT
    sf.createdDate AS date, 
    sf.cell as leadid,
    ctm.source, 
    sf.branchname,
    s.subscriptionID,
s.source,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY s.subscriptionID ORDER BY sf.createdDate) = 1 
        THEN s.contractvalue 
        ELSE NULL 
    END AS contractvalue,
    CASE 
        WHEN ROW_NUMBER() OVER (PARTITION BY s.subscriptionID ORDER BY sf.createdDate) = 1 
        THEN s.initialstatus 
        ELSE NULL 
    END AS initialstatus, format(SUM(contractvalue),2)

FROM dwh_salesforce.MarketingSalesforceLeads sf

LEFT JOIN dwh_ctmdb.calls ctm
    ON ctm.call_id = sf.ctmid 
   AND ctm.datecontacted >= '2026-01-01'

LEFT JOIN dwh_reportsdb.subscription s
    ON sf.pestRoutesSubscriptionID = s.subscriptionID
   AND s.initialstatus = 1

WHERE sf.qualifiedleadid IS NOT NULL 
    AND sf.existingaccount = 0 AND ctm.dateContacted >= '2026-01-01'
and ctmid is not null;
 