select 
	year(dateContacted) as Year, 
    month(dateContacted) as Month,
    sum(duration)/60*(.02/*+.06*/) as Cost, -- Duration is in seconds, so 0.02 is the number of dollars per minute
    format(SUM(duration)/60*(.02/* + 0.06*/),2) AS formattedCost
from dwh_ctmdb.calls
where year(dateContacted)
group by year(dateContacted), month(dateContacted)
ORDER BY YEAR DESC, MONTH DESC;