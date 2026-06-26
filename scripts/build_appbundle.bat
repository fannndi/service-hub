@echo off
cd /d "%~dp0..\frontend"
echo Building App Bundle for Play Store...
flutter build appbundle --release ^
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV
if %errorlevel% equ 0 (
  echo.
  echo AAB ready: build\app\outputs\bundle\release\app-release.aab
) else (
  echo Build failed!
)
pause
