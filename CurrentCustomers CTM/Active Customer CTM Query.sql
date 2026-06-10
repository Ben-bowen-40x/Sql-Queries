select phone1, phone2
from dwh_reportsdb.customer
where status = '1' and length(phone1) = 10 
and phone1 >  2000000000
and phone1 <= 3000000000
group by phone1