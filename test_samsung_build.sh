#!/bin/bash

# Clean previous builds
flutter clean

# Enable debug logging for build process
export FLUTTER_BUILD_VERBOSE=true

# Build with specific ABI for Samsung
flutter build apk --split-per-abi --flavor samsung \
    --target-platform android-arm64 \
    --debug \
    --verbose

# Output build info
echo "Build completed. APK location:"
echo "build/app/outputs/flutter-apk/app-samsung-arm64-v8a-debug.apk"
