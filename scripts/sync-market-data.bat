@echo off
setlocal

:: ── Dynamic Desktop path ───────────────
set "DIR=%USERPROFILE%\Desktop\fintechstocks"
set "OUT_FILE=%DIR%\url_state.txt"
set "LOG_FILE=%DIR%\sync.log"

if not defined FINTECH_API_URL set "API_BASE=https://api.fintechstocks.io/v1/market/snapshot"
if defined FINTECH_API_URL set "API_BASE=%FINTECH_API_URL%"

if not exist "%DIR%" mkdir "%DIR%"

:: ── Fetch + Save ───────────────────────
curl.exe --silent "%API_BASE%" > "%OUT_FILE%"

:: ── Log ────────────────────────────────
echo Data written now at %DATE% %TIME% (Market sync) >> "%LOG_FILE%"

endlocal
exit /b
