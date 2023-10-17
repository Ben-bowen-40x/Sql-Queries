select s.subscriptionID, s.customerID, s.dateAdded, s.dateCancelled, s.dateReactived
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.employee as e on e.employeeID = s.soldBy
