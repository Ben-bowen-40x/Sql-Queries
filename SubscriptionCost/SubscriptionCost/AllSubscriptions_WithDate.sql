select 
# Essential details
	s.customerID, s.subscriptionID, s.dateAdded,
# Additional Details
	s.serviceType, s.active, s.dateCancelled,
# Sales people who participated in the sale
	o.fullName, p.fullName, q.fullName
from dwh_reportsdb.subscription as s
	left join dwh_reportsdb.employee as o on s.soldBy = o.employeeID
	left join dwh_reportsdb.employee as p on s.soldBy2 = p.employeeID
	left join dwh_reportsdb.employee as q on s.soldBy3 = q.employeeID