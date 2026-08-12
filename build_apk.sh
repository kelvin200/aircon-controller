#!/bin/sh
# Build the Android APK. Reads API_BASE from .env and passes it via --dart-define.
set -e
cd "$(dirname "$0")/app"
. ../.env
flutter pub get
flutter build apk --debug --dart-define=API_BASE="$API_BASE"
echo "APK: build/app/outputs/flutter-apk/app-debug.apk"