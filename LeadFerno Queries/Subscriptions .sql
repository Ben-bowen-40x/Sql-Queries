select s.subscriptionID, s.customerID, s.dateAdded, s.dateCancelled, s.dateReactived
from dwh_reportsdb.subscription as s
    