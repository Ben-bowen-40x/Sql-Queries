select call_id, contact_number_clean, note
from dwh_ctmdb.calls
where sale_billable = "pending" and year(dateContacted) = 2023 and month(dateContacted) = 12
