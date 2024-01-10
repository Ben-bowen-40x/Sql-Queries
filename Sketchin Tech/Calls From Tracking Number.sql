SELECT called_at, called_at_utc, called_at_denver, note, audio,current_customer, location
FROM dwh_ctmdb.calls
where tracking_number=+18885640321 #and dateContacted between '2023-11-25' and '2023-11-30'