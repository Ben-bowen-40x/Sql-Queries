# Calls
Select 
	a.contact_number_clean, a.called_at_utc, a.time_zone, a.sale_billable
	FROM dwh_ctmdb.calls as a

# Customers
union select
   c.phone1 as "phone1", c.phone2 as "phone2", c.dateAdded, s.contractValue, c.customerID, c.subscriptionIDs, c.dateCancelled,
   case 
   	when c.statusText = 'Active' then 'true'
       else 'false'	
       end as 'status',
   case 
   	when s.initialStatusText = 'Completed' then 'true'
       else 'false'
       end as 'serviced'
	from dwh_reportsdb.customer as c
   left join dwh_reportsdb.subscription as s on c.customerID=s.customerID

# Subscription
union select 
	s.subscriptionID, s.customerID, s.dateAdded, s.dateCancelled, s.dateReactived
	from dwh_reportsdb.subscription as s

WHERE year(a.called_at) = '2023'