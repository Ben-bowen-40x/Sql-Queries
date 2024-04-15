select email as "Email", fname as "First Name", lname as "Last Name", "United States" as "Country", zip as "Zip Code", phone1 as "Primary Phone", phone2 as "Secondary Phone"
from dwh_reportsdb.customer
where statusText = 'Active' and length(phone1) = 10 and phone1 > 1000000000
group by phone1