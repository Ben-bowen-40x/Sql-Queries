@echo off

call "C:\Users\benjamin.bowen\Repos\Automate\LeadPipe.bat"
if errorlevel 1 (
    set query=LeadPipe
    goto :end
)

set query=Manual
echo %query%
"C:\Users\benjamin.bowen\AppData\Local\Microsoft\WinGet\Packages\SQLite.SQLite_Microsoft.Winget.Source_8wekyb3d8bbwe\sqlite3.exe" -header -csv "C:\Users\benjamin.bowen\Repos\LeadPipe\LeadPipe.Infrastructure\.info\leadpipe.test.db" < "C:\Users\benjamin.bowen\Repos\LeadPipe\LeadPipe.Infrastructure\.queries\AllReportAggregates.sql" > "C:\Users\benjamin.bowen\Repos\Sql-Queries\ROI Report\Temporary ROI\Manual.csv"
if errorlevel 1 goto :end
echo %query% successful!

:: ---------------------------------------
echo Opening Excel files...
set query=OpenAndSaveTemporaryROI
set "SCRIPT_PATH=%USERPROFILE%\Repos\Sql-Queries\ROI Report\Temporary ROI\OpenAndSaveTemporaryROI.ps1"

:: Check if the PowerShell script exists
if exist "%SCRIPT_PATH%" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
    
    :: Check for errors
    if errorlevel 1 (
        echo PowerShell script encountered an error with %SCRIPT_PATH%. Pausing for review...
        goto :end
    ) else (
        echo Script completed successfully.
    )
) else (
    echo PowerShell script not found!
    goto :end
)

echo Done.
echo. 
:: ---------------------------------------

echo All queries completed successfully.
goto :done

:end
echo %query% failed
pause

:done
