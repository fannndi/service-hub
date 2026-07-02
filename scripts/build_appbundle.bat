@echo off
cd /d "%~dp0..\frontend"
echo Building App Bundle for Play Store...
flutter build appbundle --release ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
if %errorlevel% equ 0 (
  echo.
  echo AAB ready: build\app\outputs\bundle\release\app-release.aab
) else (
  echo Build failed!
)
pause
