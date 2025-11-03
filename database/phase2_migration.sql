-- Phase 2: Smart Planning - Database Migration
-- Run this script in Firebase Firestore Rules or create these as code-based updates

-- Note: Firestore is a NoSQL database, so we don't need SQL migrations.
-- Instead, we'll update the TodoEntity to include these new fields.
-- This file documents the schema changes for reference.

-- New fields to add to 'todos' collection documents:
-- {
--   // Existing fields...
--
--   // Phase 2: Smart Planning fields
--   "travel_time_minutes": 0,           // Estimated travel time to location
--   "geofence_radius_meters": 500,      // Radius for location-based notifications
--   "weather_dependent": false,          // Whether task is weather-sensitive
--   "traffic_aware": true,               // Whether to use traffic for reminders
--   "preparation_time_minutes": 15,      // Time needed to prepare before leaving
--   "last_traffic_check": null,          // Timestamp of last traffic check
--   "last_weather_check": null,          // Timestamp of last weather check
--   "estimated_departure_time": null,    // Calculated departure time
-- }

-- New 'notification_settings' collection:
-- Collection: notification_settings
-- Document ID: user_id
-- {
--   "user_id": "string",
--   "location_notifications_enabled": true,
--   "traffic_notifications_enabled": true,
--   "weather_notifications_enabled": true,
--   "default_geofence_radius": 500,
--   "default_preparation_time": 15,
--   "notification_sound": "default",
--   "vibration_enabled": true,
--   "quiet_hours_start": null,           // Format: "22:00"
--   "quiet_hours_end": null,             // Format: "08:00"
--   "created_at": FieldValue.serverTimestamp(),
--   "updated_at": FieldValue.serverTimestamp()
-- }

-- Firestore Security Rules Update:
-- Add these rules to firestore.rules:

-- Allow users to read/write their own notification settings
-- match /notification_settings/{userId} {
--   allow read, write: if request.auth != null && request.auth.uid == userId;
-- }

-- Update todos rule to include new fields (existing rule already covers this)
-- match /todos/{todoId} {
--   allow read, write: if request.auth != null &&
--                      resource.data.user_id == request.auth.uid;
-- }
