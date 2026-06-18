@echo off
echo Please have your password ready
set /p host="Please enter the url of the database: "
set /p user="Please enter your username: "
set /p pass="Please enter your password: "
echo.

set query=Manual
echo %query%
"C:\Users\benjamin.bowen\AppData\Local\Microsoft\WinGet\Packages\SQLite.SQLite_Microsoft.Winget.Source_8wekyb3d8bbwe\sqlite3.exe" -header -csv "C:\Users\benjamin.bowen\Repos\LeadPipe\LeadPipe.Infrastructure\.info\leadpipe.test.db" < "C:\Users\benjamin.bowen\Repos\LeadPipe\LeadPipe.Infrastructure\.queries\AllReportAggregates.sql" > "C:\Users\benjamin.bowen\Repos\Sql-Queries\ROI Report\Temporary ROI\Manual.csv"
if errorlevel 1 goto :end
echo %query% successful!

set query=OLDROI
echo %query%
"C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe" -u %user% -p%pass% -h %host% -D dwh_reportsdb --batch < "C:\Users\benjamin.bowen\Repos\Sql-Queries\ROI Report\Leo ROI Report 2025.sql" > "C:\Users\benjamin.bowen\Repos\Sql-Queries\ROI Report\Temporary ROI\OLDROI_tsv.tsv" 2>nul
if errorlevel 1 goto :end
echo %query% successful!

set query=ROI
echo %query%
"C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe" -u %user% -p%pass% -h %host% -D dwh_reportsdb --batch < "C:\Users\benjamin.bowen\Repos\Sql-Queries\ROI Report\Stephen ROI _ CTE _ With all Columns.sql" > "C:\Users\benjamin.bowen\Repos\Sql-Queries\ROI Report\Temporary ROI\ROI.tsv" 2>nul
if errorlevel 1 goto :end
echo %feailedQuery% successful!

echo All queries completed successfully.
goto :done

:end
echo %query% failed

:done
pause
