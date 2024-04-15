select 
# Identification
s.subscriptionID, s.customerID, s.officeID, s.dateAdded, s.active, s.initialStatus, s.serviceType,

# Money
s.initialServiceTotal, s.recurringCharge, s.contractValue, s.billingFrequency,

# Timing
a.date as 'dateOfInitial', s.frequency, s.followupService, s.agreementLength, s.nextService, s.lastCompleted,

# Calculations
# Calculate the time elapsed since the initial appointment
datediff(now(), a.date) as 'daysSinceInitial', 
if
(
	s.billingFrequency < 1 and s.initialServiceTotal = s.contractValue,
    s.initialServieTotal,
    s.recurringCharge * (datediff(now(), a.date) / s.billingFrequency)
)
+ if
(
	s.followupService < s.frequency and s.followupService > 0 and datediff(now(), a.date) > s.followupService,
    recurringCharge,
    0
) 
+ s.initialServiceTotal
as 'marginalGross'
,
if
(
	frequency != 'CUSTOM'
, 
	if
    (
		datediff(now(), a.date) > s.frequency, 
		datediff(now(), a.date) / s.frequency, 
		0
	) 
	* s.recurringCharge
, 
    if
    (
		datediff(now(), a.date) > s.frequency, 
        datediff(now(), a.date), 
        0
	) 
	/ 90 * s.recurringCharge
)
+ 
	if
    (
		s.frequency != 'CUSTOM' and s.followupService < s.frequency and s.followupService > 0, 
		s.recurringCharge, 
		0
	) 
+ s.initialServiceTotal
as 'grossIncome'

from dwh_reportsdb.subscription as s
left join dwh_reportsdb.appointment as a on s.initialAppointmentID = a.appointmentID
where s.initialStatus = 1 and s.active = 1
    and year(a.date) = 2024 and month(a.date) = 1
