use dwh_ctmdb;
use dwh_reportsdb;

with calls as 
(
select call_id, contact_number_clean, dateContacted, sale_billable,
	if(sale_billable = "billable", dateContacted, null) as "billableDate", 
    if(sale_billable = "pending", dateContacted, null) as "pendingDate",
    if(sale_billable = "billable", sale_billable, null) as "billable",
    if(sale_billable = "pending", sale_billable, null) as "pending",
    note
from dwh_ctmdb.calls
where sale_billable in ("pending", "billable") and dateContacted between "2023-01-01" and "2024-01-31"
),
customers as
(
select customerID, phone1, date(dateAdded) as "dateAdded"
from dwh_reportsdb.customer
where dateCancelled > "2023-01-01"
),
calledCustomers as
(
select *,  rank() over (partition by c.contact_number_clean order by c.dateContacted asc) as "rank"
from calls as c
left join customers as b on c.contact_number_clean = b.phone1
)

select *
from calledCustomers as c
where phone1 is not null and dateAdded >= "2023-01-01" and dateAdded >= dateContacted and billable is null and c.rank = 1 
	and note not regexp 
"current customer|code(:)? (red|blue)|h.ng(s)? up|refer|tech in neighborhood|truck in .* neighborhood|truck(s)? in .* neighborhood|previous caller|rang previously|no audio|wrong number|wildlife|after hours|employment|cancel"
    and length(note) > 0
group by customerID
order by contact_number_clean asc

