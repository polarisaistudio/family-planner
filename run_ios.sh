#!/bin/bash
# Wrapper script to run Flutter on iOS with GeneratedPluginRegistrant fix

cd "$(dirname "$0")"

# Fix the GeneratedPluginRegistrant.m file
fix_plugin_registrant() {
    if [ -f "ios/Runner/GeneratedPluginRegistrant.m" ]; then
        awk '
        BEGIN { skip = 0; }
        /^#if __has_include\(<(cloud_firestore|firebase_auth)/ { skip = 1; next; }
        /^#endif/ && skip == 1 { skip = 0; next; }
        /\[FLTFirebaseFirestorePlugin registerWith/ { next; }
        /\[FLTFirebaseAuthPlugin registerWith/ { next; }
        skip == 0 { print; }
        ' ios/Runner/GeneratedPluginRegistrant.m > ios/Runner/GeneratedPluginRegistrant.m.tmp
        mv ios/Runner/GeneratedPluginRegistrant.m.tmp ios/Runner/GeneratedPluginRegistrant.m
        echo "🔧 Fixed GeneratedPluginRegistrant.m"
    fi
}

# Watch for changes and fix the file
watch_and_fix() {
    while true; do
        if [ -f "ios/Runner/GeneratedPluginRegistrant.m" ]; then
            if grep -q "cloud_firestore" ios/Runner/GeneratedPluginRegistrant.m; then
                echo "⚠️  Detected cloud_firestore in GeneratedPluginRegistrant.m, fixing..."
                fix_plugin_registrant
            fi
        fi
        sleep 1
    done
}

# Start the watcher in background
watch_and_fix &
WATCHER_PID=$!

# Trap to kill watcher on exit
trap "kill $WATCHER_PID 2>/dev/null" EXIT

# Run flutter
flutter run -d "${1:-00008140-0012746A1A7B001C}"
