-- Contact Form assessment
-- Methodology: Connect Contact forms in the Dwh to Sales Force to find contract value. Leads are defined by Dwh, Contract Value is defined by Sales Force and PestRoutes
select 
-- Forms information
	m.id as `ID`,
	m.phoneNumber as `Lead`,
    m.timestamp as `Conversion Time`,
    replace(replace(m.comments,'\n',''),'\r','') as `Contents`,
    m.form as `Location`, m.referringurl as `Referring Url`,
    case
		when (m.form like "%gclid%" or m.referringurl like "%gclid%" or m.form like "%gbraid%" or m.referringurl like "%gbraid%" or m.form like "%local-location%" or m.referringurl like "%local-location%") 
			then "Google Ads"
		when m.source is not null then m.source
        when m.source is null and referringurl is null then substring_index(m.form, "fox-pest.com/",-1)
			# This extracts the source from the referring url
        when m.source is null and referringurl regexp "utm_source=" then substring_index(substring_index(m.referringurl, "utm_source=", -1), "&", 1)
        when m.source is null and referringurl = "Not set" then substring_index(m.form, "fox-pest.com/",-1)
			# This cites the referring url as the source, which can sometimes be google.com
        when m.source is null and referringurl not like "%fox-pest.com%" then referringurl
        when m.source is null and referringurl = "https://fox-pest.com/" then m.referringurl
        when m.source is null and referringurl like "%fox-pest.com%" then substring_index(m.referringurl, "fox-pest.com/",-1)
        else "Source not found"
	end as `Extracted Source`,
	case 
		when (m.form like "%gclid%" or m.referringurl like "%gclid%" or m.form like "%gbraid%" or m.referringurl like "%gbraid%" or m.form like "%local-location%" or m.referringurl like "%local-location%") 
			then "Google Ads"
		when m.medium is not null then m.medium
        when m.medium is null and referringurl is null then substring_index(m.form, "fox-pest.com/",-1)
			# This extracts the medium from the referring url
        when m.medium is null and referringurl regexp "utm_medium=" then substring_index(substring_index(m.referringurl, "utm_medium=", -1), "&", 1)
        when m.medium is null and referringurl = "Not set" then substring_index(m.form, "fox-pest.com/",-1)
			# This cites the referring url as the medium, which can sometimes be google.com
        when m.medium is null and referringurl not like "%fox-pest.com%" then referringurl
        when m.source is null and referringurl = "https://fox-pest.com/" then m.referringurl
        when m.source is null and referringurl like "%fox-pest.com%" then substring_index(m.referringurl, "fox-pest.com/",-1)
        else "Medium not found"
	end as `Extracted Medium`,
	case
		when (m.form like "%gclid%" or m.referringurl like "%gclid%" or m.form like "%gbraid%" or m.referringurl like "%gbraid%" or m.form like "%local-location%" or m.referringurl like "%local-location%") 
			then "Google Ads"
		when m.campaign is not null then m.campaign
        when m.campaign is null and referringurl is null then substring_index(m.form, "fox-pest.com/",-1)
			# This extracts the campaign from the referring url
        when m.campaign is null and referringurl regexp "utm_campaign=" then substring_index(substring_index(m.referringurl, "utm_campaign=", -1), "&", 1)
        when m.campaign is null and referringurl = "Not set" then substring_index(m.form, "fox-pest.com/",-1)
			# This cites the referring url as the medium, which can sometimes be google.com
        when m.campaign is null and referringurl not like "%fox-pest.com%" then referringurl
        when m.source is null and referringurl = "https://fox-pest.com/" then m.referringurl
        when m.source is null and referringurl like "%fox-pest.com%" then substring_index(m.referringurl, "fox-pest.com/",-1)
        else "Campaign not found"
	end as `Extracted Campaign`,
	case
		when m.form like "%gclid%" then substring_index(m.form, "gclid=", -1)
        when m.referringurl like "%gclid%" then substring_index(m.referringurl, "gclid=", -1)
        else null
	end as `Gclid`,
	case
        when m.form like "%gbraid%" then substring_index(m.form, "gbraid=", -1)
        when m.referringurl like "%gbraid%" then substring_index(m.referringurl, "gbraid=", -1)
        else null
	end as `Gbraid`,
	case 
		when m.form like "%/blog/%" or m.referringurl like "%/blog/%" then 'Blog'
        when m.form like "%/coupons/%" or m.referringurl like "%/coupons/%" then 'Coupon Page'
        when m.form like "%/contact-us/%" or m.referringurl like "%/contact-us/%" then 'Contact Us Page'
        when m.form like "%/pest-control/%" or m.referringurl like "%/pest-control/%" then 'Pest Page'
        when m.form like "%/services/plans/%" or m.referringurl like "%/services/plans/%" then 'Service Plans Page'
        when m.form like "%/customer-portal/%" or m.referringurl like "%/customer-portal/%" then 'Customer Portal Page'
        when m.form like "%/about-us/%" or m.referringurl like "%/about-us/%" then 'About Us Page'
        when m.form like "%/frequently-asked-questions/%" or m.referringurl like "%/frequently-asked-questions/%" then 'FAQ Page'
        when m.form like "%/pest-files/%" or m.referringurl like "%/pest-files/%" then 'Pest Files'
        when m.form like "%/welcome/%" or m.referringurl like "%/welcome/%" then 'Welcome Page'
        when m.form like "%/locations/%" or m.referringurl like "%/locations/%" then 'Location Page'
        when m.form like "%/commercial/%" or m.referringurl like "%/commercial/%" then 'Commercial'
        else 'Other'
	end as `Page`,        
	-- Customers information
    s.contractValue as `Conversion Value`,
    s.subscriptionid as `Subscription ID`
    -- ,sum(s.contractValue), count(s.customerID)
from (
	select *, dense_rank() over(partition by m.phoneNumber order by m.timestamp) as ranking
    from dwh_internetmarketingdb.masterWebForm as m
    ) as m
left join dwh_salesforce.MarketingSalesforceLeads as f on m.phoneNumber = f.cell
left join dwh_reportsdb.subscription as s on f.pestroutessubscriptionid = s.subscriptionID
where m.ranking = 1 
	and s.dateadded >= '2025-01-01'
    and (s.dateAdded is null or s.dateAdded > m.timestamp)
    and m.currentCustomer = "No"
	and m.timestamp >= '2025-01-01'
    
-- group by 
	-- `Extracted Source`, `Extracted Medium`, `Extracted Campaign`
    -- `Page`
;