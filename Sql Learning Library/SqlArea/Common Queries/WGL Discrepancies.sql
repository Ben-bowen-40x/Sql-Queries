SELECT contact_number_clean, called_at, duration, note, sale_billable, source
from dwh_ctmdb.calls
Where month(called_at)=3