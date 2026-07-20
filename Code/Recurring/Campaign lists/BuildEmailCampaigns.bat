@echo off
REM Runs build_email_campaigns.py and surfaces failures loudly.
REM stdout+stderr are captured to a log so nothing gets swallowed.

setlocal
set "SCRIPT_DIR=%~dp0"
set "LOG=%SCRIPT_DIR%build_email_campaigns.log"

python "%SCRIPT_DIR%build_email_campaigns.py" > "%LOG%" 2>&1
set "RC=%ERRORLEVEL%"

type "%LOG%"

if not "%RC%"=="0" (
    echo.
    echo ******************************************************
    echo *  BUILD FAILED ^(exit code %RC%^) -- see log above.  *
    echo *  Do NOT run LOAD DATA against this output.         *
    echo ******************************************************
) else (
    echo.
    echo Build OK. email_campaigns.csv is ready for LOAD DATA.
)

pause
endlocal & exit /b %RC%
