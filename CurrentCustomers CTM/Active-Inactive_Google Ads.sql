#Active
select email as "Email", fname as "First Name", lname as "Last Name", billingCountryID as "Country", zip as "Zip", billingEmail as "Email(2)", phone1 as "Phone", phone2 as "Phone(2)"
from dwh_reportsdb.customer
where statusText = 'Active'
group by phone1;

#Inactive
select email as "Email", fname as "First Name", lname as "Last Name", billingCountryID as "Country", zip as "Zip", billingEmail as "Email(2)", phone1 as "Phone", phone2 as "Phone(2)"
from dwh_reportsdb.customer
where statusText != 'Active'
group by phone1;