#!/bin/bash
# Wrapper script to run Flutter app on iOS with Firebase plugins excluded

set -e

echo "🚀 Building Flutter app for iOS (using Firebase REST API)..."

# Navigate to project directory
cd "$(dirname "$0")"

# Build the app first (this will regenerate files)
echo "📦 Running flutter build..."
flutter build ios --no-codesign

# Fix the generated plugin registrant
echo "🔧 Fixing iOS plugin registrations..."
cd ios
./fix_ios_plugins.sh
cd ..

# Now install to device using the already-built app
echo "📱 Installing to iPhone..."
flutter install -d "${1:-00008140-0012746A1A7B001C}"

echo "✅ App deployed successfully!"
