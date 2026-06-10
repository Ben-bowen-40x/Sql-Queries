# Checking why the subscription date is sometimes before the customer start date
with customers as (
select s.subscriptionID, c.customerID, c.fullname, s.dateAdded as subadd, c.dateAdded as custadd, c.officeID, s.soldBy,
hour(c.dateAdded) - hour(s.dateAdded) as HourDiff,
c.dateAdded > s.dateAdded as custAfter,
day(c.dateAdded) = day(s.dateAdded) and month(c.dateAdded) = month(s.dateAdded) as DayMatch, 
minute(c.dateAdded) = minute(s.dateAdded) as MinuteMatch,
second(c.dateAdded) = second(s.dateAdded) as SecondMatch
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.customer as c on c.customerID = s.customerID
#where c.customerID = 1143427
)

select * from customers
where 
custAfter = 1 and 
DayMatch = 1
#and MinuteMatch = 0
and year(subadd) = 2023
