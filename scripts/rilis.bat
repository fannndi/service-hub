@echo off
cd /d "%~dp0..\frontend"
set KEYSTORE=android\release.keystore
set PROPS=android\key.properties

echo ========================================
echo   Service Me - Rilis Play Store
echo ========================================
echo.

:: Check keystore
if not exist "%KEYSTORE%" (
    echo ERROR: Keystore not found!
    echo Run: scripts\setup_keystore.bat first
    pause
    exit /b 1
)
echo [OK] Keystore: %KEYSTORE%

:: Check key.properties
if not exist "%PROPS%" (
    echo ERROR: key.properties not found!
    pause
    exit /b 1
)
echo [OK] Signing config: %PROPS%

:: Clean previous build
echo [1/3] Cleaning...
call flutter clean >nul 2>&1

:: Get version
set VERSION=1.0.0
for /f "tokens=2 delims=: " %%a in ('findstr /b "version:" pubspec.yaml') do set VERSION=%%a
set VERSION=%VERSION:+=+%
echo [2/3] Building v%VERSION%...

:: Build AAB
call flutter build appbundle --release ^
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo   BUILD SUCCESS v%VERSION%
    echo ========================================
    echo   AAB: build\app\outputs\bundle\release\app-release.aab
    echo.
    echo   Upload ke Play Console:
    echo   1. Buka https://play.google.com/console
    echo   2. Service Me ^> Production ^> Create new release
    echo   3. Upload AAB file
    echo   4. Isi "What's new"
    echo   5. Save ^> Review ^> Start rollout
) else (
    echo BUILD FAILED
)
pause
