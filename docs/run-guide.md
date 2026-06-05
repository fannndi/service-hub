# Run Guide

## Backend
1. Run `docker compose up --build` from repo root.
2. Open `http://localhost:3000/v1/health`.
3. Open Swagger at `http://localhost:3000/docs`.

## Flutter
1. Open `frontend` in Android Studio.
2. If `android/` is missing, run `flutter create --platforms=android --org id.servisgadget --project-name servisgadget_foundation .` inside `frontend`.
3. Run on emulator.
4. Default Android emulator API URL is `http://10.0.2.2:3000/v1`.

## Note
Flutter tool hung in this environment while creating Android wrapper. Source layer and `pubspec.yaml` are ready; wrapper generation should be retried from Android Studio terminal if needed.
