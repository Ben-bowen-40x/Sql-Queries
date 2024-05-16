select year(dateContacted) as Year, sum(duration)/60*.02 as High, sum(if(duration>=300,1,0))*5*.02 as fiveMinuteMax, sum(if(duration<300,duration,0))/60*.02 lessThanFive
from dwh_ctmdb.calls
group by year(dateContacted)