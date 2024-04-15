select dateContacted, called_at_denver, call_id, tracking_number, location as landingPage, note,  audio
from dwh_ctmdb.calls
where location like '%/blog/draw-a-snow-bug-with-the-sketchin-tech/%'