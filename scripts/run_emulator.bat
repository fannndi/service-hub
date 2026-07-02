@echo off
cd /d "%~dp0..\frontend"
echo Running on emulator...
flutter run -d emulator-5554 --debug ^
  --dart-define=SUPABASE_URL=%SUPABASE_URL% ^
  --dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%
pause
