#with calls as(
select 
#customer
    concat_ws(" ", c.fname, c.lname) as customerName, c.customerID, c.dateAdded, c.phone1, c.phone2, 
/*
#subscription
    s.subscriptionID, s.customerID, s.active, 
    s.soldBy, s.soldBy2, s.soldBy3, s.initialStatus, s.contractValue, s.dateAdded, o.branchName,
*/
#calls
	c1.contact_number_clean, c1.dateContacted, c1.name, c1.source, c1.sale_billable, c1.call_id,
#if the call is from a customer
	case
		when c1.dateContacted <= c.dateAdded then true
        else false
	end as becameCustomer
from dwh_ctmdb.calls c1 
left join dwh_reportsdb.customer c on c1.name = concat_ws(" ", c.fname, c.lname) or c1.contact_number_clean = c.phone1
/*left join dwh_reportsdb.subscription s on s.customerID = c.customerID
left join dwh_reportsdb.office o on o.officeID = s.officeID*/
where year(c1.dateContacted) = '2023' and c1.source in("GMB","Google My Business") and c1.tracking_number = "+19566259586"
/*)

select count(call_id), becameCustomer
from calls
group by becameCustomer
#*/