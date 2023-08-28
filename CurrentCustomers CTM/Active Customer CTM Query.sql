select phone1, phone2
from dwh_reportsdb.customer
where statusText='Active'
group by phone1