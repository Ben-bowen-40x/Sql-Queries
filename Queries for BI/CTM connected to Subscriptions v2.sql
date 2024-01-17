select 
	count(call_id) calls, ca.source, o.branchName, s.serviceType, month(called_at), year(called_at)
from dwh_ctmdb.calls ca
left join dwh_reportsdb.customer c 
on ca.contact_number_clean = c.phone1 
	or ca.contact_number_clean = c.phone2 
	or ca.name = c.fullName
left join dwh_reportsdb.subscription s 
	on s.customerID = c.customerID
left join dwh_reportsdb.office o
	on o.officeID = ca.officeID
where year(ca.called_at) = 2023 and ca.sale_billable = "billable" and subscriptionID is not null
group by source, branchName, serviceType, month(called_at),year(called_at)
