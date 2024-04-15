select count(call_id) calls, c.source, o.branchName, month(called_at), year(called_at)
from dwh_ctmdb.calls c
left join dwh_reportsdb.office o
on o.officeID = c.officeID
where year(called_at) = 2023
group by c.source, c.officeID, month(c.called_at)
limit 1000