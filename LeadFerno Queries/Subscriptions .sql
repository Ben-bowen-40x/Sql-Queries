select s.subscriptionID, s.customerID, s.dateAdded, s.dateCancelled, s.dateReactived, e.fullName,
(
	Select e.fullName 
		from dwh_reportsdb.subscription as s
        left join dwh_reportsdb.employee as e on e.employeeID=s.soldBy2
) as "SoldBy2",
(
	Select e.fullName 
		from dwh_reportsdb.subscription as s
        left join dwh_reportsdb.employee as e on e.employeeID=s.soldBy3
) as "SoldBy3"
from dwh_reportsdb.subscription as s
left join dwh_reportsdb.employee as e on e.employeeID=s.soldBy

    