select sale_billable, count(call_id), source, branchName
from dwh_ctmdb.calls as c
left join dwh_reportsdb.office as o on o.officeID=c.officeID
where month(called_at) = 4 and year(called_at) = 2024 
and source like "%LSA%"
and sale_billable = 'billable'
group by branchName
order by count(call_id) desc