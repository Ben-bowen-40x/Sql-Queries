-- Find leads and contract value by branch
select
	year(createdDate) as `Year`,
	month(createdDate) as `Month`,
	count(s.leadid) as `Leads`, 
    sum(if(c.contractvalue > 0, 1,0)) as `Sales`,
    concat( # Get the close rate (sales/leads)
		format(
			100*(sum( # Multiply by 100 to get percentage
				if(c.contractvalue > 0, 1,0) # Sale count
			)/count(s.leadid)), # Lead count
            2
		),"%"
	) as `Close Rate (Sales/Leads)`,
    sum(c.contractvalue) as `Contract Value`
    -- , max(createdDate), min(createdDate)
from dwh_salesforce.MarketingSalesforceLeads as s
left join dwh_reportsdb.subscription as c on c.subscriptionid = s.pestroutessubscriptionid
where 
	branchname is not null
    and branchname like "%orlando%"
group by year(createdDate), month(createdDate)
order by year(createdDate), month(createdDate) asc