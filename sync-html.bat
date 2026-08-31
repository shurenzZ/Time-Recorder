@echo off
REM ============================================================
REM  Time Recorder - HTML sync script (Windows)
REM  Treats Time Recorder.html as the single source of truth and
REM  copies it to the three copies:
REM    dist/index.html
REM    windows/Time Recorder.html
REM    harmony-app/entry/src/main/resources/rawfile/index.html
REM  Usage: double-click, or run sync-html.bat from repo root
REM ============================================================
cd /d "%~dp0"

set "SRC=Time Recorder.html"
set "DEST1=dist\index.html"
set "DEST2=windows\Time Recorder.html"
set "DEST3=harmony-app\entry\src\main\resources\rawfile\index.html"

if not exist "%SRC%" (
  echo [ERROR] source not found: %SRC%
  pause
  exit /b 1
)

echo Syncing %SRC% to the three copies ...
copy /y "%SRC%" "%DEST1%" >nul && echo   [OK] %DEST1%
copy /y "%SRC%" "%DEST2%" >nul && echo   [OK] %DEST2%
copy /y "%SRC%" "%DEST3%" >nul && echo   [OK] %DEST3%

echo.
echo Done. All three targets (web / Windows / HarmonyOS) now use the same HTML.
pause
