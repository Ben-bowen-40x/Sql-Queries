use dwh_reportsdb; # Pest Net
with aggregate19 as (
   select 
	  2019 as Year,
      0 as Spend,
      count(origin.subscriptionID) as SubsOrigin, # Year 2019
      sum(origin.contractValue) as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, # Year 2020
      sum(stayed1Y.contractValue) as CVAfterY1,
      count(stayed2Y.subscriptionID) as SubsAfterY2, # Year 2021
      sum(stayed2Y.contractValue) as CVAfterY2,
      count(stayed3Y.subscriptionID) as SubsAfterY3, # Year 2022
      sum(stayed3Y.contractValue) as CVAfterY3,
      count(stayed4Y.subscriptionID) as SubsAfterY4, # Year 2023 
      sum(stayed4Y.contractValue) as CVAfterY4,
      count(stayed5Y.subscriptionID) as SubsAfterY5, # Year 2024
      sum(stayed5Y.contractValue) as CVAfterY5
   from ( 
      # Retrieves customers who started in a specific year and cancelled in a specific year. Also, joins subscriptions to CTM phone calls, which SHOULD eliminate those that were marked incorrectly as Internet source in PestRoutes
   	select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2019 and month(s.dateAdded) in (8,9,10,11,12) and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2019)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as origin
   left join (
	   select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2019 and month(s.dateAdded) in (8,9,10,11,12) and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2019,2020)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed1Y on origin.subscriptionID = stayed1Y.subscriptionID
   left join (
	   select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2019 and month(s.dateAdded) in (8,9,10,11,12) and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2019,2020,2021)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed2Y on origin.subscriptionID = stayed2Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2019 and month(s.dateAdded) in (8,9,10,11,12) and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2019,2020,2021,2022)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed3Y on origin.subscriptionID = stayed3Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2019 and month(s.dateAdded) in (8,9,10,11,12) and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2019,2020,2021,2022,2023)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed4Y on origin.subscriptionID = stayed4Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2019 and month(s.dateAdded) in (8,9,10,11,12) and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2019,2020,2021,2022,2023,2024)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed5Y on origin.subscriptionID = stayed5Y.subscriptionID
), aggregate20 as (
   select 
	  2020 as Year,
      0 as Spend,
      count(origin.subscriptionID) as SubsOrigin, # Year 2020
      sum(origin.contractValue) as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, # Year 2021
      sum(stayed1Y.contractValue) as CVAfterY1,
      count(stayed2Y.subscriptionID) as SubsAfterY2, # Year 2022
      sum(stayed2Y.contractValue) as CVAfterY2,
      count(stayed3Y.subscriptionID) as SubsAfterY3, # Year 2023
      sum(stayed3Y.contractValue) as CVAfterY3,
      count(stayed4Y.subscriptionID) as SubsAfterY4, # Year 2024
      sum(stayed4Y.contractValue) as CVAfterY4,
      if(count(stayed5Y.subscriptionID) = count(stayed4Y.subscriptionID), 0, count(stayed5Y.subscriptionID)) as SubsAfterY5, # Year 2025
      if(sum(stayed5Y.contractValue) = sum(stayed4Y.contractValue), 0, sum(stayed5Y.contractValue)) as CVAfterY5
   from ( 
      # Retrieves customers who started in a specific year and cancelled in a specific year. Also, joins subscriptions to CTM phone calls, which SHOULD eliminate those that were marked incorrectly as Internet source in PestRoutes
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2020 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2020)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as origin
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2020 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2020,2021)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed1Y on origin.subscriptionID = stayed1Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2020 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2020,2021,2022)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed2Y on origin.subscriptionID = stayed2Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2020 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2020,2021,2022,2023)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed3Y on origin.subscriptionID = stayed3Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2020 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2020,2021,2022,2023,2024)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed4Y on origin.subscriptionID = stayed4Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2020 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2020,2021,2022,2023,2024,2025)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed5Y on origin.subscriptionID = stayed5Y.subscriptionID
), aggregate21 as (
   select 
	  2021 as Year,
      0 as Spend,
      1357 as SubsOrigin, # Year 2021
      950186 as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, # Year 2022
      sum(stayed1Y.contractValue) as CVAfterY1,
      count(stayed2Y.subscriptionID) as SubsAfterY2, # Year 2023
      sum(stayed2Y.contractValue) as CVAfterY2,
      count(stayed3Y.subscriptionID) as SubsAfterY3, # Year 2024
      sum(stayed3Y.contractValue) as CVAfterY3,
      if(count(stayed4Y.subscriptionID) = count(stayed3Y.subscriptionID), 0, count(stayed4Y.subscriptionID)) as SubsAfterY4, # Year 2025
      if(sum(stayed4Y.contractValue) = sum(stayed3Y.contractValue), 0, sum(stayed4Y.contractValue)) as CVAfterY4,
      if(count(stayed5Y.subscriptionID) = count(stayed4Y.subscriptionID), 0, count(stayed5Y.subscriptionID)) as SubsAfterY5, # Year 2026
      if(sum(stayed5Y.contractValue) = sum(stayed4Y.contractValue), 0, sum(stayed5Y.contractValue)) as CVAfterY5
   from ( 
      # Retrieves customers who started in a specific year and cancelled in a specific year. Also, joins subscriptions to CTM phone calls, which SHOULD eliminate those that were marked incorrectly as Internet source in PestRoutes
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2021 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2021)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as origin
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2021 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2021,2022)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed1Y on origin.subscriptionID = stayed1Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2021 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2021,2022,2023)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed2Y on origin.subscriptionID = stayed2Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2021 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2021,2022,2023,2024)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed3Y on origin.subscriptionID = stayed3Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2021 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2021,2022,2023,2024,2025)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed4Y on origin.subscriptionID = stayed4Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2021 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2021,2022,2023,2024,2025,2026)
         and c.source like "%pestnet%"
	  group by s.customerID
   ) as stayed5Y on origin.subscriptionID = stayed5Y.subscriptionID
), aggregate22 as (
   select 
   	  2022 as Year,
      0 as Spend,
      1382 as SubsOrigin, # Year 2022
      1031488 as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, # Year 2023
      sum(stayed1Y.contractValue) as CVAfterY1,
      count(stayed2Y.subscriptionID) as SubsAfterY2, # Year 2024
      sum(stayed2Y.contractValue) as CVAfterY2,
      if(count(stayed3Y.subscriptionID) = count(stayed2Y.subscriptionID), 0, count(stayed3Y.subscriptionID)) as SubsAfterY3, # Year 2025
      if(sum(stayed3Y.contractValue) = sum(stayed2Y.contractValue), 0, sum(stayed3Y.contractValue)) as CVAfterY3,
      if(count(stayed4Y.subscriptionID) = count(stayed3Y.subscriptionID), 0, count(stayed4Y.subscriptionID)) as SubsAfterY4, # Year 2026
      if(sum(stayed4Y.contractValue) = sum(stayed3Y.contractValue), 0, sum(stayed4Y.contractValue)) as CVAfterY4,
      if(count(stayed5Y.subscriptionID) = count(stayed4Y.subscriptionID), 0, count(stayed5Y.subscriptionID)) as SubsAfterY5, # Year 2027
      if(sum(stayed5Y.contractValue) = sum(stayed4Y.contractValue), 0, sum(stayed5Y.contractValue)) as CVAfterY5
   from ( 
      # Retrieves customers who started in a specific year and cancelled in a specific year. Also, joins subscriptions to CTM phone calls, which SHOULD eliminate those that were marked incorrectly as Internet source in PestRoutes
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2022 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2022)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as origin
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2022 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2022,2023)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed1Y on origin.subscriptionID = stayed1Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2022 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2022,2023,2024)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed2Y on origin.subscriptionID = stayed2Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2022 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2022,2023,2024,2025)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed3Y on origin.subscriptionID = stayed3Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2022 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2022,2023,2024,2025,2026)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed4Y on origin.subscriptionID = stayed4Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2022 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2022,2023,2024,2025,2026,2027)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed5Y on origin.subscriptionID = stayed5Y.subscriptionID
), aggregate23 as (
   select 
   	2023 as Year,
      442000 as Spend,
      1240 as SubsOrigin, # Year 2023
      905182 as CVOrigin,
      count(stayed1Y.subscriptionID) as SubsAfterY1, # Year 2024
      sum(stayed1Y.contractValue) as CVAfterY1,
      if(count(stayed2Y.subscriptionID) = count(stayed1Y.subscriptionID), 0, count(stayed2Y.subscriptionID)) as SubsAfterY2, # Year 2025
      if(sum(stayed2Y.contractValue) = sum(stayed1Y.contractValue), 0, sum(stayed2Y.contractValue)) as CVAfterY2,
      if(count(stayed3Y.subscriptionID) = count(stayed2Y.subscriptionID), 0, count(stayed3Y.subscriptionID)) as SubsAfterY3, # Year 2026
      if(sum(stayed3Y.contractValue) = sum(stayed2Y.contractValue), 0, sum(stayed3Y.contractValue)) as CVAfterY3,
      if(count(stayed4Y.subscriptionID) = count(stayed3Y.subscriptionID), 0, count(stayed4Y.subscriptionID)) as SubsAfterY4, # Year 2027
      if(sum(stayed4Y.contractValue) = sum(stayed3Y.contractValue), 0, sum(stayed4Y.contractValue)) as CVAfterY4,
      if(count(stayed5Y.subscriptionID) = count(stayed4Y.subscriptionID), 0, count(stayed5Y.subscriptionID)) as SubsAfterY5, # Year 2028
      if(sum(stayed5Y.contractValue) = sum(stayed4Y.contractValue), 0, sum(stayed5Y.contractValue)) as CVAfterY5
   from ( 
      # Retrieves customers who started in a specific year and cancelled in a specific year. Also, joins subscriptions to CTM phone calls, which SHOULD eliminate those that were marked incorrectly as Internet source in PestRoutes
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2023 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2023)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as origin
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2023 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2023,2024)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed1Y on origin.subscriptionID = stayed1Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2023 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2023,2024,2025)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed2Y on origin.subscriptionID = stayed2Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2023 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2023,2024,2025,2026)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed3Y on origin.subscriptionID = stayed3Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2023 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2023,2024,2025,2026,2027)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed4Y on origin.subscriptionID = stayed4Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2023 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2023,2024,2025,2026,2027,2028)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed5Y on origin.subscriptionID = stayed5Y.subscriptionID
), aggregate24 as (
   select 
   	2024 as Year,
      475000 as Spend,
      985 as SubsOrigin, # Year 2024
      791318 as CVOrigin,
      if(count(stayed1Y.subscriptionID) = count(origin.subscriptionID), 0, count(stayed1Y.subscriptionID)) as SubsAfterY1, # Year 2025
      if(sum(stayed1Y.contractValue) = sum(origin.contractValue), 0, sum(stayed1Y.contractValue)) as CVAfterY1,
      if(count(stayed2Y.subscriptionID) = count(stayed1Y.subscriptionID), 0, count(stayed2Y.subscriptionID)) as SubsAfterY2, # Year 2026
      if(sum(stayed2Y.contractValue) = sum(stayed1Y.contractValue), 0, sum(stayed2Y.contractValue)) as CVAfterY2,
      if(count(stayed3Y.subscriptionID) = count(stayed2Y.subscriptionID), 0, count(stayed3Y.subscriptionID)) as SubsAfterY3, # Year 2027
      if(sum(stayed3Y.contractValue) = sum(stayed2Y.contractValue), 0, sum(stayed3Y.contractValue)) as CVAfterY3,
      if(count(stayed4Y.subscriptionID) = count(stayed3Y.subscriptionID), 0, count(stayed4Y.subscriptionID)) as SubsAfterY4, # Year 2028
      if(sum(stayed4Y.contractValue) = sum(stayed3Y.contractValue), 0, sum(stayed4Y.contractValue)) as CVAfterY4,
      if(count(stayed5Y.subscriptionID) = count(stayed4Y.subscriptionID), 0, count(stayed5Y.subscriptionID)) as SubsAfterY5, # Year 2029
      if(sum(stayed5Y.contractValue) = sum(stayed4Y.contractValue), 0, sum(stayed5Y.contractValue)) as CVAfterY5
   from ( 
      # Retrieves customers who started in a specific year and cancelled in a specific year. Also, joins subscriptions to CTM phone calls, which SHOULD eliminate those that were marked incorrectly as Internet source in PestRoutes
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2024 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2024)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as origin
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2024 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2024,2025)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed1Y on origin.subscriptionID = stayed1Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2024 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2024,2025,2026)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed2Y on origin.subscriptionID = stayed2Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2024 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2024,2025,2026,2027)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed3Y on origin.subscriptionID = stayed3Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2024 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2024,2025,2026,2027,2028)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed4Y on origin.subscriptionID = stayed4Y.subscriptionID
   left join (
      select s.subscriptionID, s.dateAdded, s.dateCancelled, s.contractValue 
	   from dwh_ctmdb.calls as c 
      left join dwh_reportsdb.customer as u on c.contact_number_clean = u.phone1
      left join dwh_reportsdb.subscription as s on s.customerID = u.customerID
      where year(s.dateAdded) = 2024 and s.initialStatus = 1
         and s.source like "%internet%"
         and year(s.dateCancelled) not in (2024,2025,2026,2027,2028,2029)
         and c.source like "%pestnet%"
	   group by s.customerID
   ) as stayed5Y on origin.subscriptionID = stayed5Y.subscriptionID
), unity as (
	select *
	from aggregate21
	union select * from aggregate19
	union select * from aggregate20
	union select * from aggregate21
	union select * from aggregate22
	union select * from aggregate23
	union select * from aggregate24
)

SELECT
# Items from "Unity"
Year, Spend, SubsOrigin, CVOrigin, SubsAfterY1, CVAfterY1, SubsAfterY2, CVAfterY2, SubsAfterY3, CVAfterY3, SubsAfterY4, CVAfterY4, SubsAfterY5, CVAfterY5,

# Total Gain Calculations
CVOrigin + CVAfterY1 + CVAfterY2 + CVAfterY3 + CVAfterY4 + CVAfterY5 as TotalEarned,
CVAfterY1 + CVAfterY2 + CVAfterY3 + CVAfterY4 + CVAfterY5 as EarnedAFTEROrigin

from unity
order by Year asc;