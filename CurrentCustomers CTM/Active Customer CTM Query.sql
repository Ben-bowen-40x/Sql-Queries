SELECT 
case 
	when phone1 is not null then phone1
    when phone2 is not null then phone2
    end as 'number'
FROM dwh_reportsdb.customer
where statusText = 'Active' or status = 1
;
