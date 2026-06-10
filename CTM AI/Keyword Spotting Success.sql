with b1 as (select * from dwh_ctmdb.call_tags where tag = 'b1'),
customer as (select * from dwh_ctmdb.call_tags where tag = 'in customer list'),
joinder as (
SELECT 
#Tags
	b1.tag as 'b1Tag', b1.call_id as 'b1callId', customer.tag as 'cTag', customer.call_id as 'cCallId', 
#CTM 
    c.call_id, sale_billable, called_at, note, contact_number_clean,
#Pest Routes
	ca.phone1,
#Meta
	if(customer.tag = 'in customer list',1,0) as 'isCustomer',
	if(b1.tag = 'b1' and sale_billable = 'billable', 1, 0) as 'correctBillable',
    if(b1.tag = 'b1' and sale_billable = 'billable' and ca.phone1 is not null, 1, 0) as 'currentCustomer',
	if(b1.tag is null and customer.tag is null, 1,0) as 'exclude'
FROM dwh_ctmdb.calls as c 
left join b1 on b1.call_id=c.call_id
left join customer on customer.call_id = c.call_id
left join dwh_reportsdb.customer as ca on c.contact_number_clean = ca.phone1
)

select j.*, count(j.correctBillable) 
from joinder as j
where year(j.called_at) = 2024 and month(j.called_at) in (4,5) 
	and j.exclude = 0 and j.isCustomer = 0 #and correctBillable = 1
group by sale_billable