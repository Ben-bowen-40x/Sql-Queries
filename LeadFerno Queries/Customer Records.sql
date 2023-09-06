select c.phone1, c.phone2, c.dateAdded, s.contractValue, c.customerID, c.subscriptionIDs, c.dateCancelled
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
   left join dwh_reportsdb.subscription as s 
   on c.customerID=s.customerID
where c.statusText = "Active"