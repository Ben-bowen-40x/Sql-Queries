select c.fullName, c.phone1, c.email, o.branchName
from dwh_reportsdb.customer as c
	left join dwh_reportsdb.subscription as s on c.customerID = s.customerID
	left join dwh_reportsdb.office as o on c.officeID = o.officeID
where 
	c.status > 0
	and (s.serviceType not like "%sentricon%" and s.serviceType not like "%termite%" and s.initialStatus > 0) 
	and c.officeID in (
		#2, #Providence - RI
		#3, #Virginia Beach - VA
		4, #Baton Rouge - LA
		#5, #Buffalo - NY
		#6, #Chicago South - IL
		7, #Corpus Christi - TX
		#8, #Lexington - KY
		#9, #Long Island - NY
		10, #Lubbock - TX
		11, #McAllen - TX
		12, #Midland - TX
		#13, #Oxford - CT
		#14, #Rochester - NY
		#15, #Westchester - NY
		#16, #Albany - NY
		#17, #Syracuse - NY
		#18, #Merrimack Valley - MA
		19, #Lafayette - LA
		#20, #Harrisburg - PA
		#21, #Manchester - NH
		#22,	#Bloomington - IL
		23, #Northshore - LA
		#24,	#Newport News - VA
		25 #Dallas Fort Worth Northwest - TX
		#26,	#Northern VA /DC West - DC
		#27, #Boston North Shore - MA
		#28,	#Orlando West - FL
		#29, #Pittsburgh - PA
		#30, #New Jersey Central - NJ
		#31, #Hartford - CT
		#32,	#Chicago North - IL
		#33	#Orchard Park - NY
    )
group by email