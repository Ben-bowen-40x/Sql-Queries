select s.subscriptionID, s.customerID, s.dateAdded, s.dateCancelled, s.dateReactived
from dwh_reportsdb.subscription as s
where year(s.dateAdded) in("2023","2022") #and s.subscriptionID ="899810"
    