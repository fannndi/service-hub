@echo off
cd /d "%~dp0"
echo ========================================
echo   Service Me - Build APK (auto env)
echo ========================================
echo.

:: Baca SUPABASE_URL dari .env
for /f "tokens=1,* delims==" %%a in ('findstr /b "SUPABASE_URL=" "..\.env"') do set "SUPABASE_URL=%%b"
for /f "tokens=1,* delims==" %%a in ('findstr /b "SUPABASE_ANON_KEY=" "..\.env"') do set "SUPABASE_ANON_KEY=%%b"

if "%SUPABASE_URL%"=="" (
  echo ERROR: SUPABASE_URL tidak ditemukan di .env
  pause
  exit /b 1
)
if "%SUPABASE_ANON_KEY%"=="" (
  echo ERROR: SUPABASE_ANON_KEY tidak ditemukan di .env
  pause
  exit /b 1
)

echo [OK] SUPABASE_URL = %SUPABASE_URL%
echo [OK] SUPABASE_ANON_KEY loaded
echo.

call build_apk.bat
