@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo Current project folder:
echo %CD%
echo.

if not exist "pubspec.yaml" goto :wrong_folder
if not exist "lib\main.dart" goto :wrong_folder

where flutter >nul 2>nul
if errorlevel 1 (
  echo ERROR: Flutter was not found in PATH.
  pause
  exit /b 1
)

echo [1/4] Cleaning generated files...
flutter clean
if errorlevel 1 goto :failed
if exist ".dart_tool" rmdir /s /q ".dart_tool"
if exist "pubspec.lock" del /q "pubspec.lock"

echo.
echo [2/4] Resolving packages...
flutter pub get
if errorlevel 1 goto :failed

echo.
echo [3/4] Verifying Supabase dependency...
findstr /I /C:"supabase_flutter" ".dart_tool\package_config.json" >nul
if errorlevel 1 (
  echo ERROR: supabase_flutter was not written to package_config.json.
  echo Confirm that this exact folder contains pubspec.yaml and try again.
  pause
  exit /b 1
)

echo.
echo [4/4] Running Flutter analyzer...
flutter analyze
set "RESULT=%ERRORLEVEL%"
echo.
if "%RESULT%"=="0" echo Analysis completed without issues.
pause
exit /b %RESULT%

:wrong_folder
echo ERROR: This is not the Flutter project root.
echo Open the folder that directly contains pubspec.yaml and lib\main.dart.
pause
exit /b 1

:failed
echo.
echo Flutter could not prepare the project. Review the first red error above.
pause
exit /b 1
