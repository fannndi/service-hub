@echo off
cd /d "%~dp0..\frontend"
echo Running on emulator...
flutter run -d emulator-5554 --debug ^
  --dart-define=SUPABASE_URL=https://eboplbemgtvmviwhdlfa.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_sLbPJCOjGT9GRGZBosGlsQ_4cpeOMRV
pause
