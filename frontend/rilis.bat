@echo off
REM =============================================
REM Service Me — Release Build Script
REM =============================================

setlocal enabledelayedexpansion

REM ---- Supabase Credentials (wajib dari env) ----
if "%SUPABASE_URL%"=="" echo ERROR: SUPABASE_URL env tidak diset! && exit /b 1
if "%SUPABASE_ANON_KEY%"=="" echo ERROR: SUPABASE_ANON_KEY env tidak diset! && exit /b 1

REM ---- Build Type (default: apk) ----
set BUILD_TYPE=%1
if "%BUILD_TYPE%"=="" set BUILD_TYPE=apk

echo ========================================
echo  Service Me — Build %BUILD_TYPE%
echo ========================================

REM ---- Flutter Clean ----
echo [1/4] Cleaning...
call flutter clean >nul 2>&1

REM ---- Get Packages ----
echo [2/4] Getting packages...
call flutter pub get >nul 2>&1

REM ---- Build ----
echo [3/4] Building %BUILD_TYPE%...
if /i "%BUILD_TYPE%"=="aab" (
  flutter build appbundle --release ^
    --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
    --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
) else (
  flutter build apk --release ^
    --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
    --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
)

if %errorlevel% neq 0 (
  echo [ERROR] Build gagal!
  exit /b 1
)

REM ---- Output ----
echo [4/4] Selesai!
if /i "%BUILD_TYPE%"=="aab" (
  echo  AAB: build\app\outputs\bundle\release\app-release.aab
) else (
  echo  APK: build\app\outputs\flutter-apk\app-release.apk
)
echo.
echo  Gunakan: rilis.bat apk   (untuk APK release)
echo  Gunakan: rilis.bat aab   (untuk AAB Play Store)
echo ========================================
