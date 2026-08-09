@echo off
setlocal
cd /d "%~dp0"
echo Deploying secure admin user-update Edge Function...
supabase functions deploy update-user
if errorlevel 1 (
  echo.
  echo Deployment failed. Make sure the Supabase CLI is installed and this project is linked.
  pause
  exit /b 1
)
echo.
echo update-user deployed successfully.
pause
