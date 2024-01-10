select call_id, tracking_number, location as landingPage, note, dateContacted, audio
from dwh_ctmdb.calls
where location like '%draw-a-snail-with-the-sketchin-tech%'