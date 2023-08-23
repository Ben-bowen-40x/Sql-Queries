Select
case
when cs.customerID IN ('4884600407','3954672296','5562236429','2499442546','3153837978','2557223813',
'3916019625','2043109899','5659245411','4287759362','2594010705','1567026297','9109993096','8588818494','5659245441','8138373690',
'8242438560','4313995931','7263307645','7713864811','3557581058','8642341252','5844274480','6061812199','6146213948','8438334847',
'9634801997','3739346694','1092125678','3312241670') Then 'Google LSA'
Else
'Google Ads'
End as source,
	year(cs.dbDate) as Year,
    Month(cs.dbDate) as Month,
    Round(sum(cs.cost), 2) as Spend
from dwh_googleadsdb.campaign_stats cs
INNER JOIN dwh_googleadsdb.campaign_def cd ON cd.campaignID = cs.campaignID
LEFT JOIN dwh_reportsdb.office o ON o.officeID = cd.officeID
LEFT JOIN dwh_reportsdb.merchants m ON m.merchantID = o.merchantID
WHERE year(cs.dbDate) IN ('2023', '2022', '2021')
GROUP BY Source, Year, Month
ORDER BY Source, Year ASC, Month ASC;