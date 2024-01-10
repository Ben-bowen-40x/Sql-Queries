select fullName, phone1, phone2, email, statusText, status
from dwh_reportsdb.customer
where statusText='Active'
group by phone1