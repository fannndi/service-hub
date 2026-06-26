@echo off
cd /d "%~dp0..\frontend"

echo ========================================
echo   Service Me - Build APK
echo ========================================
echo.
echo   APK ini bisa diinstall langsung di HP.
echo   Bagikan file ini ke teman untuk testing.
echo.

:: Clean previous build
echo [1/3] Cleaning...
call flutter clean >nul 2>&1

:: Get version
set VERSION=1.0.0
for /f "tokens=2 delims=: " %%a in ('findstr /b "version:" pubspec.yaml') do set VERSION=%%a
echo [2/3] Building v%VERSION%...

:: Build APK
call flutter build apk --release ^
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV

if errorlevel 1 goto error

echo.
echo ========================================
echo   BUILD SUCCESS v%VERSION%
echo ========================================
echo.
echo   APK: build\app\outputs\flutter-apk\app-release.apk
echo.
echo   Cara kirim ke teman:
echo   1. Buka folder build\app\outputs\flutter-apk\
echo   2. Copy app-release.apk
echo   3. Kirim lewat WhatsApp / Telegram
echo.
echo   Di HP teman: buka APK ^> Install
echo   (mungkin perlu izin "Install unknown apps")
goto end

:error
echo BUILD FAILED - cek error di atas.

:end
pause
