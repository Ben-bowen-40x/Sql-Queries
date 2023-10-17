select s.subscriptionID, s.customerID, s.dateAdded, s.dateCancelled, s.dateReactived, e.fullName, f.fullName as "SoldBy2", g.fullName as "SoldBy3"
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.employee as e on e.employeeID=s.soldBy
left join dwh_reportsdb.employee as f on f.employeeID=s.soldBy2
left join dwh_reportsdb.employee as g on g.employeeID=s.soldBy3