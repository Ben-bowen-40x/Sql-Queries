select ani, disposition, campaign, timestamp
from dwh_five9db.calls
where disposition like "%spam%" 
and campaign in("Inside Sales", "Sales Spanish") 
and campaignType = "Inbound"
and month(timestamp) = 5 and year(timestamp) = 2024 #and day(timestamp) in (1,2,3,4,5,6,7)
group by ani