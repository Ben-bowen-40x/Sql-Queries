select 
	count(ca.call_id) "Calls", ca.source "Source", o.branchName "Branch", s.serviceType "Service", month(ca.dateContacted) "Month", year(ca.dateContacted) "Year"
from dwh_ctmdb.calls ca
left join dwh_reportsdb.customer c on ca.contact_number_clean = c.phone1 
left join dwh_reportsdb.subscription s on s.customerID = c.customerID
left join dwh_reportsdb.office o on o.officeID = ca.officeID
where year(ca.dateContacted) = 2023 and ca.sale_billable = "billable"
group by ca.call_id, ca.source, ca.officeID, s.serviceType, month(ca.dateContacted)
