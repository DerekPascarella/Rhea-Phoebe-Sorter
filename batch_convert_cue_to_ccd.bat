@echo off
setlocal EnableExtensions

rem -------------------------------------------------------------
rem  configuration: tool and log locations (all beside script)
rem -------------------------------------------------------------
set "BIN=%~dp0"
set "C2C=%BIN%cue2ccd.exe"
if not exist "%C2C%" (
    echo FATAL: cue2ccd.exe not found in "%BIN%"
    pause
    exit /b 1
)

set "LOG_OK=%BIN%success.log"
set "LOG_ERR=%BIN%error.log"
> "%LOG_OK%" echo Run started %date% %time%
set "ERRFLAG=0"

rem -------------------------------------------------------------
rem  check input argument
rem -------------------------------------------------------------
if "%~1"=="" (
    echo Usage: %~nx0 ^<root_folder^>
    pause
    exit /b 1
)
set "ROOT=%~1"
if not exist "%ROOT%" (
    echo "%ROOT%" not found
    pause
    exit /b 1
)

rem -------------------------------------------------------------
rem  main loop: every *.cue under the tree
rem -------------------------------------------------------------
for /R "%ROOT%" %%F in (*.cue) do call :convert "%%~fF"

rem ------------------ finish ------------------
echo.
if "%ERRFLAG%"=="1" (
    echo One or more titles failed.  See "error.log" for details.
) else (
    echo All conversions completed successfully.
)
pause
exit /b 0


:convert
rem -------------------------------------------------------------
rem  %1 = absolute path to a .cue
rem -------------------------------------------------------------
set "CUE=%~1"

for %%A in ("%~dp1.") do (
    set "DIRFULL=%%~fA"
    set "GAME=%%~nxA"
    set "PARENT=%%~dpA"
)

set "BASE=%~n1"
set "CCDROOT=%DIRFULL%\ccd"
set "OUT=%CCDROOT%\%BASE%"

if not exist "%CCDROOT%" md "%CCDROOT%" >nul

echo Converting "%CUE%"
"%C2C%" "%CUE%" "%CCDROOT%" >nul 2>nul
if errorlevel 1 (
    call :logError "%CUE%" converter error
    echo   FAILED  converter error
    goto :eof
)

if not exist "%OUT%\" (
    call :logError "%CUE%" output missing
    echo   FAILED  missing output
    goto :eof
)

pushd "%PARENT%" >nul

set "NEW=%GAME%__new"
set "OLD=%GAME%__old"

move "%GAME%\ccd\%BASE%" "%NEW%" >nul
if errorlevel 1 (
    popd
    call :logError "%CUE%" move failed
    echo   FAILED  move failed
    goto :eof
)

ren "%GAME%" "%OLD%" >nul
if errorlevel 1 (
    popd
    call :logError "%CUE%" rename original failed
    echo   FAILED  rename original
    goto :eof
)

ren "%NEW%" "%GAME%" >nul
if errorlevel 1 (
    ren "%OLD%" "%GAME%" >nul
    popd
    call :logError "%CUE%" rename new failed
    echo   FAILED  rename new
    goto :eof
)

rd /s /q "%OLD%" 2>nul
rd /s /q "%GAME%\ccd" 2>nul
popd >nul

>> "%LOG_OK%" echo "%CUE%"
echo   SUCCESS
goto :eof


:logError
rem -------------------------------------------------------------
rem  %* = entire error line
rem -------------------------------------------------------------
if "%ERRFLAG%"=="0" (
    > "%LOG_ERR%" echo Run started %date% %time%
    set ERRFLAG=1
)
>> "%LOG_ERR%" echo %*
goto :eof
