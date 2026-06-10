/* Definition:
A cancelled customer is a recurring subscription (hpp, sentricon, yard) that has been cancelled 
excluding the cancelation reason of Quit Before Start, Duplicate, Program Switch, Previous Customer, and Never Received Initial
*/
-- Cancelled customers before a certain date
select
	c.fname as 'FirstName', c.lname as 'LastName', c.fullname as 'FullName', c.email as 'Email', 
    c.datecancelled as 'CancelDate', c.customerid as 'CustomerID'
from dwh_reportsdb.customer as c
where c.datecancelled < date_sub(curdate(), interval 90 day) and c.dateCancelled > '2000-01-01'
	and c.status = 0
    ;