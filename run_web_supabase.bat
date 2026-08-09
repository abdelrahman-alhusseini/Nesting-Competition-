@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "SUPABASE_URL=https://ryzedpbkzspwvrnrppij.supabase.co"
set "KEY_FILE=.supabase_publishable_key"
set "SUPABASE_PUBLISHABLE_KEY="
set "SKIP_PUB_GET="
if /I "%~1"=="--skip-pub-get" set "SKIP_PUB_GET=1"

if not exist "pubspec.yaml" (
  echo ERROR: Run this file from the project folder containing pubspec.yaml.
  pause
  exit /b 1
)

if not defined SKIP_PUB_GET (
  flutter pub get
  if errorlevel 1 goto :failed
)

if exist "%KEY_FILE%" set /p SUPABASE_PUBLISHABLE_KEY=<"%KEY_FILE%"

if not defined SUPABASE_PUBLISHABLE_KEY (
  echo.
  echo Paste the client-safe Publishable key from Supabase:
  echo Project Settings ^> API Keys ^> Publishable key
  set /p SUPABASE_PUBLISHABLE_KEY=Key: 
  if not defined SUPABASE_PUBLISHABLE_KEY goto :missing
  >"%KEY_FILE%" echo %SUPABASE_PUBLISHABLE_KEY%
)

rem Remove common copy/paste characters.
set "SUPABASE_PUBLISHABLE_KEY=%SUPABASE_PUBLISHABLE_KEY:"=%"
set "SUPABASE_PUBLISHABLE_KEY=%SUPABASE_PUBLISHABLE_KEY:'=%"
set "SUPABASE_PUBLISHABLE_KEY=%SUPABASE_PUBLISHABLE_KEY:,=%"

if /I not "%SUPABASE_PUBLISHABLE_KEY:~0,15%"=="sb_publishable_" (
  if /I not "%SUPABASE_PUBLISHABLE_KEY:~0,3%"=="eyJ" (
    echo.
    echo ERROR: This does not look like a Supabase Publishable or legacy anon key.
    echo Run reset_supabase_key.bat and copy a fresh client key.
    pause
    exit /b 1
  )
)

flutter run -d chrome --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_PUBLISHABLE_KEY=%SUPABASE_PUBLISHABLE_KEY%
exit /b %errorlevel%

:missing
echo No key was entered. Nothing was started.
pause
exit /b 1

:failed
echo.
echo Flutter could not install the project packages.
pause
exit /b 1
