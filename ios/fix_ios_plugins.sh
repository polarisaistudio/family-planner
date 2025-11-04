#!/bin/bash
# Script to remove Firebase plugin registrations from iOS

echo "Fixing iOS plugin registrations (removing Firebase)..."

# Use awk to remove Firebase plugin blocks from GeneratedPluginRegistrant.m
awk '
BEGIN { skip = 0; }
/^#if __has_include\(<(cloud_firestore|firebase_auth|firebase_core)/ { skip = 1; next; }
/^#endif/ && skip == 1 { skip = 0; next; }
skip == 0 && !/\[FLTFirebase.*Plugin registerWith/ { print; }
' Runner/GeneratedPluginRegistrant.m > Runner/GeneratedPluginRegistrant.m.tmp

mv Runner/GeneratedPluginRegistrant.m.tmp Runner/GeneratedPluginRegistrant.m

echo "✅ iOS plugins fixed - Firebase removed"
