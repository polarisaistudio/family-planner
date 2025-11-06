#!/bin/bash
# Script to remove Firebase plugin registrations from iOS (except firebase_core and firebase_messaging)

echo "Fixing iOS plugin registrations (removing Firebase Auth/Firestore)..."

# Use awk to remove Firebase plugin blocks from GeneratedPluginRegistrant.m
# Keep firebase_core and firebase_messaging for FCM support
awk '
BEGIN { skip = 0; }
/^#if __has_include\(<(cloud_firestore|firebase_auth)/ { skip = 1; next; }
/^#endif/ && skip == 1 { skip = 0; next; }
/\[FLTFirebaseFirestorePlugin registerWith/ { next; }
/\[FLTFirebaseAuthPlugin registerWith/ { next; }
skip == 0 { print; }
' Runner/GeneratedPluginRegistrant.m > Runner/GeneratedPluginRegistrant.m.tmp

mv Runner/GeneratedPluginRegistrant.m.tmp Runner/GeneratedPluginRegistrant.m

echo "✅ iOS plugins fixed - Firebase Auth/Firestore removed, Core/Messaging kept"
