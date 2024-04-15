Select call_id, dateContacted, source, duration, sale_billable
from dwh_ctmdb.calls
where year(dateContacted) in (2022, 2023)
