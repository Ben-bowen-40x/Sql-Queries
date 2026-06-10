select count(call_id) as 'calls'
from dwh_ctmdb.calls
where sale_billable = 'billable' 
and year(called_at) = 2024 and month(called_at) = 4 
and source like '%elocal%'