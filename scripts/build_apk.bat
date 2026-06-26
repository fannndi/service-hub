@echo off
cd /d "%~dp0..\frontend"
echo Building APK for sharing...
flutter build apk --release ^
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV
if %errorlevel% equ 0 (
  echo.
  echo APK ready: build\app\outputs\flutter-apk\app-release.apk
) else (
  echo Build failed!
)
pause
