-- Calls that do not connect to Sales Force
with notConnected as (
select c.call_id, c.audio, leadid, a.fullname
from dwh_ctmdb.calls as c
left join dwh_salesforce.MarketingSalesforceLeads as f on c.call_id = f.ctmid
left join dwh_five9db.calls as v on v.callid = f.five9id
left join dwh_five9db.agent as a on a.agentid = v.agentid
where 
	leadid is null # Only for calls NOT connected to SF
    -- leadid is not null and a.fullname is not null # only or calls connected to SF
and called_at >= "2025-08-01" and length(audio) > 5
limit 500
), connected as (
select c.call_id, c.audio, leadid, a.fullname
from dwh_ctmdb.calls as c
left join dwh_salesforce.MarketingSalesforceLeads as f on c.call_id = f.ctmid
left join dwh_five9db.calls as v on v.callid = f.five9id
left join dwh_five9db.agent as a on a.agentid = v.agentid
where 
	-- leadid is null # Only for calls NOT connected to SF
    leadid is not null and a.fullname is not null # only or calls connected to SF
and called_at >= "2025-08-01" and length(audio) > 5
limit 500
)

select * from notConnected
union
select * from connected