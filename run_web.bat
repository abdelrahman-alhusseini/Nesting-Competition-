@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo ================================================
echo  Michael ^& Son Nesting Champions - Step 1 Login
echo ================================================
echo Project folder: %CD%
echo.

if not exist "pubspec.yaml" goto :wrong_folder
if not exist "lib\main.dart" goto :wrong_folder

where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: Flutter was not found in PATH.
  pause
  exit /b 1
)

echo [1/4] Cleaning old generated files...
flutter clean
if errorlevel 1 goto :failed
if exist ".dart_tool" rmdir /s /q ".dart_tool"
if exist "pubspec.lock" del /q "pubspec.lock"

echo.
echo [2/4] Installing packages...
flutter pub get
if errorlevel 1 goto :failed

echo.
echo [3/4] Verifying supabase_flutter...
findstr /I /C:"supabase_flutter" ".dart_tool\package_config.json" >nul
if errorlevel 1 (
  echo ERROR: supabase_flutter is missing from package_config.json.
  echo You are probably not in the folder containing this project's pubspec.yaml.
  pause
  exit /b 1
)

echo.
echo [4/4] Starting Chrome...
call "%~dp0run_web_supabase.bat" --skip-pub-get
exit /b %ERRORLEVEL%

:wrong_folder
echo ERROR: pubspec.yaml or lib\main.dart is missing here.
echo Extract the ZIP once and run this file beside pubspec.yaml.
pause
exit /b 1

:failed
echo.
echo Flutter could not prepare the project. Review the first red error above.
pause
exit /b 1
