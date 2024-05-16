with b1 as (select * from dwh_ctmdb.call_tags where tag = 'b1'),
customer as (select * from dwh_ctmdb.call_tags where tag = 'in customer list'),
joinder as (
SELECT 
#Tags
	b1.tag as 'b1Tag', b1.call_id as 'b1callId', customer.tag as 'cTag', customer.call_id as 'cCallId', 
#CTM 
    c.call_id, sale_billable, called_at, note, contact_number_clean,
#Meta
	if(customer.tag = 'in customer list',1,0) as 'isCustomer',
	if(b1.tag = 'b1' and sale_billable = 'billable', 1, 0) as 'correctBillable',
	if(b1.tag is null and customer.tag is null, 1,0) as 'include'
FROM dwh_ctmdb.calls as c 
left join b1 on b1.call_id=c.call_id
left join customer on customer.call_id = c.call_id
)

select j.*, c.phone1, (correctBillable = 0 and phone1 is not null) as currentCustomer, count(j.correctBillable) 
from joinder as j
left join dwh_reportsdb.customer as c on j.contact_number_clean = c.phone1
where year(j.called_at) = 2024 and month(j.called_at) in (4,5) 
	and j.include = 0 and j.isCustomer = 0 and correctBillable = 1
group by sale_billable