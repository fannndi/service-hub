@echo off
cd /d "%~dp0..\frontend"

echo ========================================
echo   Service Me - Rilis Play Store
echo ========================================
echo.

:: Cek keystore
if not exist "android\release.keystore" (
    echo ERROR: release.keystore tidak ditemukan!
    echo.
    echo   Generate dulu: keytool -genkey -v -keystore android/release.keystore
    echo                -alias service_me -keyalg RSA -keysize 2048 -validity 10000
    pause
    exit /b 1
)
echo [OK] Keystore ditemukan

:: Cek key.properties
if not exist "android\key.properties" (
    echo ERROR: key.properties tidak ditemukan!
    pause
    exit /b 1
)
echo [OK] key.properties ditemukan

:: Verifikasi storeFile path di key.properties
findstr /b "storeFile" android\key.properties >nul
if errorlevel 1 (
    echo ERROR: storeFile tidak ditemukan di key.properties!
    pause
    exit /b 1
)

:: Clean
echo [1/3] Membersihkan...
call flutter clean >nul 2>&1

:: Version
for /f "tokens=2 delims=: " %%a in ('findstr /b "version:" pubspec.yaml') do set VERSION=%%a
echo [2/3] Membangun v%VERSION%...

:: Build AAB
echo [3/3] flutter build appbundle --release ...
call flutter build appbundle --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%

if errorlevel 1 goto error

echo.
echo ========================================
echo   BUILD SUCCESS v%VERSION%
echo ========================================
echo.
echo   AAB: build\app\outputs\bundle\release\app-release.aab
echo.
echo   Upload ke Play Console:
echo   1. Buka https://play.google.com/console
echo   2. Service Me ^> Production ^> Create new release
echo   3. Upload AAB file
echo   4. Isi "What's new" (e.g. "Rilis perdana")
echo   5. Save ^> Review ^> Start rollout
echo.
echo   Keystore: android\release.keystore
echo   Alias:    service_me
echo.
echo   Lihat data.md untuk password keystore!
goto end

:error
echo.
echo BUILD FAILED - cek error di atas.
echo.
echo   Tips: pastikan JDK terinstall dan ANDROID_HOME diset.

:end
pause
