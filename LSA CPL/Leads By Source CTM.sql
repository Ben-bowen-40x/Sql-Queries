Select 
sum(if(c.sale_billable="billable" and c.source like "%LSA%", 1, 0)) as Leads
from dwh_ctmdb.calls as c
where year(c.called_at)=2023 and month(c.called_at)=09