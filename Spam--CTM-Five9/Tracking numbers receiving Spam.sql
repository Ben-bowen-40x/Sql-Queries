select count(c.call_id) as 'Calls', c.tracking_number, c.numbers_name
from dwh_ctmdb.calls as c 
left join dwh_five9db.calls as f on c.contact_number_clean = f.customerNumber
where disposition like '%Spam%' #and year(c.dateContacted) = 2024
group by c.tracking_number
order by count(c.call_id) desc;

with calls as (
select call_id, contact_number_clean, tracking_number, numbers_name
from dwh_ctmdb.calls
group by contact_number_clean
),
spam as (
select customerNumber
from dwh_five9db.calls
where disposition like "%Spam%"
group by customerNumber
),
combined as(
select * from spam as s
left join calls as c on c.contact_number_clean = s.customerNumber
)
select count(customerNumber) as "Calls", tracking_number, numbers_name
from combined
group by tracking_number;

select count(callID)
from dwh_five9db.calls 
where disposition like "%Spam%"