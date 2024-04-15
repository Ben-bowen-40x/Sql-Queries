#sum duration
select count(call_id), sum(duration), month(dateContacted) as month, year(dateContacted) as year
from dwh_ctmdb.calls
where year(dateContacted) >= 2021 and source regexp "ad|LSA|elocal|goodzer|biz|pestnet"
group by month(dateContacted), year(dateContacted);

# Median numbers
select call_id, duration, month(dateContacted), year(dateContacted)
from dwh_ctmdb.calls
where year(dateContacted) = 2021 and month(dateContacted) = 2;

# Average Duration
select count(call_id), avg(duration), count(call_id)*avg(duration) as projectedDuration, sum(duration), month(dateContacted), year(dateContacted)
from dwh_ctmdb.calls
where year(dateContacted) >= 2021
group by month(dateContacted), year(dateContacted)