select c.phone1 as "phone1", c.phone2 as "phone2", c.dateAdded, s.contractValue, c.customerID, c.subscriptionIDs, c.dateCancelled, e.fullName
,
case 
	when c.statusText = 'Active' then 'true'
    else 'false'	
    end as 'status'
,
case 
	when s.initialStatusText = 'Completed' then 'true'
    else 'false'
    end as 'serviced'
from dwh_reportsdb.customer as c
   left join dwh_reportsdb.subscription as s on c.customerID=s.customerID
   left join dwh_reportsdb.appointment as a on c.customerID=a.customerID
   left join dwh_reportsdb.employee as e on a.employeeID=e.employeeID