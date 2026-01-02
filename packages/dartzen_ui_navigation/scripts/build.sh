#!/bin/bash

flutter build apk --release --dart-define=DZ_PLATFORM=android
flutter build ios --release --dart-define=DZ_PLATFORM=ios
flutter build macos --release --dart-define=DZ_PLATFORM=macos
flutter build linux --release --dart-define=DZ_PLATFORM=linux
flutter build windows --release --dart-define=DZ_PLATFORM=windows
flutter build web --release --dart-define=DZ_PLATFORM=web