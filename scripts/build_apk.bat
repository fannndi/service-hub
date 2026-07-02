@echo off
cd /d "%~dp0..\frontend"

echo ========================================
echo   Service Me - Build APK (untuk sharing)
echo ========================================
echo.
echo   APK ini release-signed, bisa diinstall
echo   langsung di HP teman untuk testing.
echo.

:: Cek keystore
if not exist "android\release.keystore" (
    echo [WARN] Keystore tidak ditemukan! Pakai debug sign.
    echo        Hasil APK: PLAY STORE TIDAK AKAN MENERIMA.
)

:: Clean
echo [1/3] Membersihkan...
call flutter clean >nul 2>&1

:: Version
for /f "tokens=2 delims=: " %%a in ('findstr /b "version:" pubspec.yaml') do set VERSION=%%a
echo [2/3] Membangun v%VERSION%...

:: Build APK
echo [3/3] flutter build apk --release ...
call flutter build apk --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%

if errorlevel 1 goto error

echo.
echo ========================================
echo   BUILD SUCCESS v%VERSION%
echo ========================================
echo.
echo   APK: build\app\outputs\flutter-apk\app-release.apk (release signed)
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
echo.
echo BUILD FAILED - cek error di atas.

:end
pause
