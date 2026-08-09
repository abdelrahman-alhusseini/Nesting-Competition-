@echo off
cd /d "%~dp0"

echo Create an EMPTY GitHub repository first (do not add a README or .gitignore).
set /p REMOTE_URL=Paste the GitHub repository URL: 

if "%REMOTE_URL%"=="" (
  echo No repository URL entered.
  pause
  exit /b 1
)

if not exist ".git" (
  git init -b main
  git add .
  git -c user.name="Abdelrahman Alhusseini" -c user.email="abdelrahman-alhusseini@users.noreply.github.com" commit -m "Connect Nesting Champions to Supabase"
)

git remote remove origin 2>nul
git remote add origin "%REMOTE_URL%"
git branch -M main
git push -u origin main

pause
