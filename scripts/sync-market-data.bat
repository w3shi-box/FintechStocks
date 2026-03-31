@echo off
:: =============================================================================
::  FintechStocks - Market Data Sync (Desktop version)
:: =============================================================================

setlocal enabledelayedexpansion

:: ── Cache directory → Desktop ────────────────────────────────────────────────
set "CACHE_DIR=C:\Users\Vignesh\Desktop\fintechstocks"
set "DATA_DIR=%CACHE_DIR%\market-data"
set "LOG_DIR=%CACHE_DIR%\logs"
set "STATE_FILE=%CACHE_DIR%\last-sync.json"
set "LOCK_FILE=%CACHE_DIR%\sync.lock"

:: ── Config ───────────────────────────────────────────────────────────────────
if not defined FINTECH_API_URL set "API_BASE=https://api.fintechstocks.io/v1"
if defined FINTECH_API_URL set "API_BASE=%FINTECH_API_URL%"

if not defined FINTECH_API_KEY set "API_KEY="
if defined FINTECH_API_KEY set "API_KEY=%FINTECH_API_KEY%"

:: ── Date/Time tags ───────────────────────────────────────────────────────────
for /f "tokens=1-3 delims=/" %%a in ("%DATE:~4%") do (
  set "MM=%%a"
  set "DD=%%b"
  set "YYYY=%%c"
)
for /f "tokens=1-3 delims=:." %%a in ("%TIME: =0%") do (
  set "HH=%%a"
  set "MIN=%%b"
  set "SEC=%%c"
)

set "DATE_TAG=%YYYY%-%MM%-%DD%"
set "TIME_TAG=%HH%%MIN%%SEC%"

set "SNAPSHOT_FILE=%DATA_DIR%\%DATE_TAG%\snapshot_%TIME_TAG%.json"
set "PORTFOLIO_FILE=%DATA_DIR%\%DATE_TAG%\portfolio_%TIME_TAG%.json"
set "LOG_FILE=%LOG_DIR%\sync-%DATE_TAG%.log"

:: ── Create directories ───────────────────────────────────────────────────────
if not exist "%DATA_DIR%\%DATE_TAG%" mkdir "%DATA_DIR%\%DATE_TAG%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

:: ── Lock ─────────────────────────────────────────────────────────────────────
if exist "%LOCK_FILE%" (
  echo [%DATE% %TIME%] Another sync is running. Exiting. >> "%LOG_FILE%"
  exit /b 0
)
echo %~f0 > "%LOCK_FILE%"

echo.
echo  [FintechStocks] Market Data Sync
echo  Cache: %CACHE_DIR%
echo  ──────────────────────────────────
echo.

set "ERRORS=0"

:: ── Fetch market snapshot ────────────────────────────────────────────────────
echo  [*] Fetching market snapshot...

curl.exe ^
  --silent ^
  --output "%SNAPSHOT_FILE%" ^
  --write-out "%%{http_code}" ^
  --max-time 15 ^
  --header "Accept: application/json" ^
  --header "X-Api-Key: %API_KEY%" ^
  "%API_BASE%/market/snapshot" > "%TEMP%\http_code.txt" 2>> "%LOG_FILE%"

set /p HTTP_CODE=<"%TEMP%\http_code.txt"

if "%HTTP_CODE%"=="200" (
  echo      OK - snapshot saved
) else (
  echo      WARNING - HTTP %HTTP_CODE%
  set /a ERRORS+=1
  echo {"error":"http_%HTTP_CODE%"} > "%SNAPSHOT_FILE%"
)

:: ── Fetch portfolio ──────────────────────────────────────────────────────────
echo  [*] Fetching portfolio...

curl.exe ^
  --silent ^
  --output "%PORTFOLIO_FILE%" ^
  --write-out "%%{http_code}" ^
  --max-time 15 ^
  --header "Accept: application/json" ^
  --header "X-Api-Key: %API_KEY%" ^
  "%API_BASE%/portfolio/summary" > "%TEMP%\http_code.txt" 2>> "%LOG_FILE%"

set /p HTTP_CODE=<"%TEMP%\http_code.txt"

if "%HTTP_CODE%"=="200" (
  echo      OK - portfolio saved
) else (
  echo      WARNING - HTTP %HTTP_CODE%
  set /a ERRORS+=1
  echo {"error":"http_%HTTP_CODE%"} > "%PORTFOLIO_FILE%"
)

:: ── Write state file ─────────────────────────────────────────────────────────
(
  echo {
  echo   "last_sync": "%DATE% %TIME%",
  echo   "snapshot": "%SNAPSHOT_FILE:\=\\%",
  echo   "portfolio": "%PORTFOLIO_FILE:\=\\%",
  echo   "cache_dir": "%CACHE_DIR:\=\\%"
  echo }
) > "%STATE_FILE%"

:: ── Cleanup ──────────────────────────────────────────────────────────────────
del "%LOCK_FILE%" 2>nul

:: ── Summary ──────────────────────────────────────────────────────────────────
echo.
echo  Summary
echo  ───────────────────────────────
echo  Cache dir : %CACHE_DIR%
echo  Data dir  : %DATA_DIR%\%DATE_TAG%
echo  Log file  : %LOG_FILE%
echo  State     : %STATE_FILE%

if %ERRORS%==0 (
  echo  Status    : Success
) else (
  echo  Status    : Errors = %ERRORS%
)

echo.
echo [%DATE% %TIME%] Sync complete >> "%LOG_FILE%"

endlocal
exit /b %ERRORS%