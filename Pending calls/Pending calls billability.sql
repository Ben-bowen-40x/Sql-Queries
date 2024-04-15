with pending as 
(select c.call_id, c.contact_number_clean, c.dateContacted, u.customerID, u.phone1, date(u.dateAdded) as "Start Date", rank() over (partition by c.call_id order by u.customerID asc) as "Rank", c.note
from dwh_ctmdb.calls as c
	left join dwh_reportsdb.customer as u on u.phone1 = c.contact_number_clean
where 
    year(u.dateAdded) = 2024 and month(u.dateAdded) = 1 and year(c.dateContacted) = 2024 and month(c.dateContacted) = 1
    and c.sale_billable = "pending" and c.contact_number_clean is not null and c.contact_number_clean >= 2000000000 and u.dateAdded >= c.dateContacted
group by u.customerID)

select *
from pending
where pending.Rank = 1