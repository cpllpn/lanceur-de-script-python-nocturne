@echo off
setlocal EnableExtensions
chcp 65001 >nul
set PYTHONIOENCODING=utf-8

REM LANCEUR NOCTURNE
REM Nuit : HA WoL 01:30 -> tache Planificateur 01:40 -> scripts -> shutdown
REM Test : nightly_orchestrator.bat --force --no-shutdown

set "FORCE=0"
set "NO_SHUTDOWN=0"
if /I "%~1"=="--force" set "FORCE=1"
if /I "%~2"=="--force" set "FORCE=1"
if /I "%~1"=="--no-shutdown" set "NO_SHUTDOWN=1"
if /I "%~2"=="--no-shutdown" set "NO_SHUTDOWN=1"

set "LANCEUR_DIR=%~dp0"
set "LOG_DIR=%LANCEUR_DIR%logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "LOG=%LOG_DIR%\orchestrator_last.log"

>>"%LOG%" echo ============================================================
>>"%LOG%" echo Debut orchestrateur %date% %time%
>>"%LOG%" echo FORCE=%FORCE% NO_SHUTDOWN=%NO_SHUTDOWN%
>>"%LOG%" echo ============================================================

echo.
echo ============================================================
echo  LANCEUR NOCTURNE
echo  Debut : %date% %time%
echo  Log   : %LOG%
echo ============================================================
echo.

if "%FORCE%"=="1" goto run_ok
goto check_window

:check_window
powershell -NoProfile -Command "$d=Get-Date; $ok=([int]$d.DayOfWeek -ge 2 -and [int]$d.DayOfWeek -le 6 -and $d.Hour -ge 1 -and $d.Hour -lt 3); if($ok){ Write-Host '[i] Fenetre OK'; exit 0 } else { Write-Host '[i] Skip : hors fenetre 01h-03h mar-sam.'; exit 1 }"
if errorlevel 1 goto skip_exit
goto run_ok

:skip_exit
>>"%LOG%" echo [i] Skip
echo Rien a faire - PC reste allume.
endlocal
exit /b 0

:run_ok
if "%FORCE%"=="1" echo [i] Mode --force : ignore la fenetre horaire.
if "%FORCE%"=="1" >>"%LOG%" echo [i] Mode --force

set "PYEXE=py"
where py >nul 2>nul
if errorlevel 1 goto try_python313
goto have_py

:try_python313
if exist "%LocalAppData%\Programs\Python\Python313\python.exe" (
  set "PYEXE=%LocalAppData%\Programs\Python\Python313\python.exe"
) else (
  set "PYEXE=python"
)

:have_py
set "ERR_GLOBAL=0"

echo.
echo [1/2] Analyses financieres americaines...
>>"%LOG%" echo [1/2] Analyses financieres americaines...
pushd "C:\Users\gatti\Documents\analyses-financieres"
"%PYEXE%" nightly_watchlist_run.py --no-shutdown --force
set "ERR1=%ERRORLEVEL%"
popd
echo       Code retour = %ERR1%
>>"%LOG%" echo Code retour script1 = %ERR1%
if not "%ERR1%"=="0" set "ERR_GLOBAL=1"

echo.
echo [2/2] US Leadership Tracker...
>>"%LOG%" echo [2/2] US Leadership Tracker...
pushd "C:\Users\gatti\Documents\Surveillance de la domination du S&P 500"
"%PYEXE%" sp500_dominance_tracker.py
set "ERR2=%ERRORLEVEL%"
popd
echo       Code retour = %ERR2%
>>"%LOG%" echo Code retour script2 = %ERR2%
if not "%ERR2%"=="0" set "ERR_GLOBAL=1"

echo.
echo ============================================================
echo  Fin chaine - ERR_GLOBAL=%ERR_GLOBAL% - %date% %time%
echo ============================================================
>>"%LOG%" echo Fin chaine ERR_GLOBAL=%ERR_GLOBAL% %date% %time%

if "%NO_SHUTDOWN%"=="1" goto no_off
goto do_shutdown

:no_off
echo [TEST] Pas d extinction (--no-shutdown).
>>"%LOG%" echo [TEST] Pas d extinction
endlocal
exit /b %ERR_GLOBAL%

:do_shutdown
echo Extinction du PC dans 60 secondes (fin des scripts)...
>>"%LOG%" echo Extinction dans 60s
shutdown /s /t 60 /c "Lanceur nocturne termine"
endlocal
exit /b %ERR_GLOBAL%