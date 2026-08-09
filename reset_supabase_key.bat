@echo off
cd /d "%~dp0"
if exist ".supabase_publishable_key" del ".supabase_publishable_key"
echo Saved Supabase key removed.
echo Run run_web.bat and paste a fresh Publishable key.
pause
