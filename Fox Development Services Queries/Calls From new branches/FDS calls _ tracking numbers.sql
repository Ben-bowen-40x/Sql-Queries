# Numbers from new Fox Development Services websites

select contact_number_clean, tracking_number, numbers_name, audio
from dwh_ctmdb.calls
where tracking_number = 2078020015 # portland, ME
or tracking_number = 3192467609 # Iowa city, IA
or tracking_number = 8508087973 # Pensacola, FL
or tracking_number = 5083885786 # springfield, MA
