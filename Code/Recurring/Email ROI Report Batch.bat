@echo off
setlocal EnableExtensions

REM ============================================================
REM RunEmailROIReport.bat
REM 1) Rebuild email_campaigns.csv via BuildEmailCampaigns.bat
REM 2) Run Email ROI report.sql -> Email ROI report.tsv
REM 3) Launch OpenEmailROIReport.ps1
REM
REM 2026-07-21: Each stage gates the next on exit code so a
REM failed campaign build or failed query never opens a stale
REM report as if it were fresh.
REM ============================================================

REM ---- Configuration -----------------------------------------
set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Workbench 8.0 CE\mysql.exe"
set "RECURRING=%USERPROFILE%\Repos\Sql-Queries\Code\Recurring"
set "SQL_FILE=%RECURRING%\Email ROI report.sql"
set "TSV_FILE=%RECURRING%\Email ROI report.tsv"
set "ERR_LOG=%RECURRING%\email_roi_report_query_err.log"
set "PS1_FILE=%RECURRING%\OpenEmailROIReport.ps1"

REM Connection settings - fill in host/user; password is prompted
REM at runtime via -p so it never lives in this file.
set "DB_HOST=foxdata.cikjfjulz1fg.us-east-2.rds.amazonaws.com"
set "DB_PORT=3306"
set "DB_USER=Ben_bowen"

REM ---- Step 1: Build email campaigns CSV ---------------------
echo [%date% %time%] Step 1: Building email campaigns...
call "%~dp0BuildEmailCampaigns.bat"
if errorlevel 1 (
    echo [%date% %time%] ERROR: BuildEmailCampaigns.bat failed with exit code %errorlevel%.
    echo Aborting - not running query against a possibly stale campaign list.
    goto :error
)
echo [%date% %time%] Campaign build complete.

REM ---- Step 2: Run query, capture TSV + errors ---------------
echo [%date% %time%] Step 2: Running Email ROI report query...

if not exist "%MYSQL_EXE%" (
    echo [%date% %time%] ERROR: mysql.exe not found at "%MYSQL_EXE%".
    goto :error
)
if not exist "%SQL_FILE%" (
    echo [%date% %time%] ERROR: SQL file not found at "%SQL_FILE%".
    goto :error
)

REM Clear previous error log so its presence/contents always reflect the current run only.
if exist "%ERR_LOG%" del "%ERR_LOG%"

REM --batch = tab-separated output with column headers, no boxes.
REM stdout -> TSV, stderr -> error log.
"%MYSQL_EXE%" --host=%DB_HOST% -D "dwh_reportsdb" --port=%DB_PORT% --user=%DB_USER% -p ^
    --batch --local-infile=1 ^
    < "%SQL_FILE%" > "%TSV_FILE%" 2> "%ERR_LOG%"

if errorlevel 1 (
    echo [%date% %time%] ERROR: Query failed. Details in "%ERR_LOG%":
    type "%ERR_LOG%"
    goto :error
)

REM mysql can exit 0 while still writing warnings to stderr;
REM surface them but don't abort.
for %%A in ("%ERR_LOG%") do if %%~zA GTR 0 (
    echo [%date% %time%] WARNING: Query succeeded but wrote to stderr:
    type "%ERR_LOG%"
)

echo [%date% %time%] Query complete. Output: "%TSV_FILE%"

REM ---- Step 3: Open the report -------------------------------
echo [%date% %time%] Step 3: Launching report viewer...
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1_FILE%"
if errorlevel 1 (
    echo [%date% %time%] ERROR: OpenEmailROIReport.ps1 exited with code %errorlevel%.
    exit /b 1
)

:ending
echo [%date% %time%] Done.
endlocal
pause
exit /b 0

:error
pause
exit /b 1