@echo off
cd /d "%~dp0"
set /p SUPABASE_URL=Supabase Project URL: 
set /p SUPABASE_PUBLISHABLE_KEY=Supabase Publishable Key: 

if "%SUPABASE_URL%"=="" (
  echo Supabase URL is required.
  pause
  exit /b 1
)
if "%SUPABASE_PUBLISHABLE_KEY%"=="" (
  echo Supabase publishable key is required.
  pause
  exit /b 1
)

flutter pub get
flutter run -d chrome --dart-define=SUPABASE_URL=%SUPABASE_URL% --dart-define=SUPABASE_PUBLISHABLE_KEY=%SUPABASE_PUBLISHABLE_KEY%
pause
