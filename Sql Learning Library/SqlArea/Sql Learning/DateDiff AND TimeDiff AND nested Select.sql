SELECT inbound.inbound_timestamp, outbound.timestamp AS outbound_timestamp, inbound.customernumber as inbound_phone, outbound.customernumber as outbound_phone,
   DATEDIFF(outbound.timestamp, inbound.inbound_timestamp) AS days_passed,
   timediff(outbound.timestamp, inbound.inbound_timestamp) as Hours_passed 
FROM (
   SELECT timestamp AS inbound_timestamp, customernumber
   FROM dwh_five9db.calls
   WHERE campaign LIKE '%sale%'
   AND callCategory = 'inbound'
   AND YEAR(timestamp) = 2023
) AS inbound
JOIN (
   SELECT timestamp, customernumber
   FROM dwh_five9db.calls
   WHERE campaign LIKE 'Abandon Recall'
   AND callCategory LIKE 'Outbound'
   AND YEAR(timestamp) = 2023
) AS outbound ON inbound.customernumber = outbound.customernumber
where datediff(outbound.timestamp, inbound.inbound.inbound_timestamp) between 0 and 1
and timediff (outbound.timestamp, inbound.inbound.inbound_timestamp) >= 1 ;