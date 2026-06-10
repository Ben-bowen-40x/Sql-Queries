-- Generate Leadferno Google Ads data for upload
-- Provide aggregates for Google Ads data in order to verify validity/ comparability against the C# equivalent

with subs as (
    select 
        -- Customer fields
        c.customerid, 
        s.dateadded as subscriptiondate,
        phone1, phone2,
        c.datecancelled, 
        convert_tz(c.dateadded, 'America/Los_Angeles', 'UTC') as customerStartDate,
        c.commercialAccount,
        -- Subscription fields
        s.subscriptionid, 
        s.contractvalue, 
        s.initialstatus, 
        s.active, 
        s.datecancelled as subCxlDate, 
        convert_tz(s.dateadded, 'America/Los_Angeles', 'UTC') as subsStartDate,
        concat(
            soldby,
            if(soldby2 is not null, concat(' | ', soldby2), ''),
            if(soldby3 is not null, concat(' | ', soldby3), '')
        ) as sellers,
        dense_rank() over (partition by s.customerid order by date(s.dateadded)) as ranking
    from dwh_reportsdb.subscription as s
    left join dwh_reportsdb.customer as c on c.customerid = s.customerid
    where s.dateadded >= '2025-01-01' -- and s.dateadded <= '2025-03-31'
			-- s.customerid in (1087583,1087664,1087749,1087824)
    order by c.customerid
),
filteredSubs as (
    select *
    from subs
    where ranking = 1
), messages as (
    select
        l.phone as messagePhone,
        substring(l.phone, 3, 10) as phoneStripped,
        l.messageDate,
        regexp_replace(l.contents, ',|\n|\n\r|\r|\r\n', '| ') as messageContents,
        l.source,
        s.*,
        least(s.customerStartDate, s.subsStartDate) as earliestStart,
        -- Message arrived before the customer/sub existed, and within 60 days prior
        messageDate < least(s.customerStartDate, s.subsStartDate)
            and messageDate > date_sub(least(s.customerStartDate, s.subsStartDate), interval 60 day)
            as is_im_lead,
        -- Commercial: message arrived any time before earliest start
        commercialAccount = 1
            and messageDate < least(s.customerStartDate, s.subsStartDate)
            as is_commercial_lead
    from dwh_leadferno.leadferno_messages as l
    left join filteredSubs as s on l.phone in (concat('+1', s.phone1), concat('+1', s.phone2))
    where s.initialstatus = 1 -- and s.active = 1
)
select
    phoneStripped                               as `Phone Number`,
    messageDate                                 as `Date of Message`,
    messageContents                             as `Message Contents`,
    source                                      as `Message Source`,
    if(is_im_lead, 'TRUE', 'FALSE')             as `IM Lead`,
    if(is_commercial_lead, 'TRUE', 'FALSE')     as `Commercial Lead`,
    customerid                                  as `Customer ID`,
    if(active = 1, 'TRUE', 'FALSE')             as `Subscription is Active`,
    customerStartDate                           as `Customer Record Start Date`,
    datecancelled                               as `Customer Cancel Date`,
    subscriptionid                              as `Subscription ID`,
    if(initialstatus = 1, 'TRUE', 'FALSE')      as `Completed Initial`,
    contractvalue                               as `Contract Value`,
    subsStartDate                               as `Subscription Start Date`,
    subCxlDate                                  as `Subscription Cancel Date`,
    sellers                                     as `Sellers`
from messages
where is_im_lead or is_commercial_lead
    -- and messageDate between '2025-07-01' and '2025-07-31'
    -- and active = 1
    -- and commercialAccount = 0
order by messageDate