SELECT 
    b.phone1,
    b.phone2,
    a.dateAdded,
    a.customerID,
    a.contractValue,
    a.activeText
FROM
    dwh_reportsdb.subscription a
        LEFT JOIN
    dwh_reportsdb.customer b ON a.customerID = b.customerID