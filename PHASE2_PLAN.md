# Phase 2: Smart Planning - Implementation Plan

## Overview
Phase 2 adds intelligent notification features based on location, traffic, and weather conditions to help users better plan their day.

## Features to Implement

### 1. Location-Based Notifications
**Goal**: Remind users about tasks when they arrive at or leave relevant locations

#### Components:
- Geofencing setup for task locations
- Background location tracking
- Proximity-based notifications
- Location permission handling

#### User Stories:
- As a user, I want to be notified when I'm near a shopping location about my shopping tasks
- As a user, I want to be reminded about tasks when I arrive at work
- As a user, I want to customize the notification radius (e.g., 500m, 1km)

### 2. Traffic Integration
**Goal**: Adjust reminder times based on real-time traffic conditions

#### Components:
- Google Maps/Apple Maps API integration
- Travel time calculation
- Traffic condition monitoring
- Smart departure time suggestions

#### User Stories:
- As a user, I want to be notified earlier if there's heavy traffic to my appointment
- As a user, I want to see estimated travel time to my appointments
- As a user, I want automatic adjustment of reminder times based on traffic

### 3. Weather Integration
**Goal**: Provide weather-aware notifications and suggestions

#### Components:
- Weather API integration (OpenWeatherMap or similar)
- Weather condition monitoring
- Weather-based suggestions
- Outfit/preparation recommendations

#### User Stories:
- As a user, I want to know if it will rain when I have outdoor tasks
- As a user, I want suggestions to reschedule outdoor activities during bad weather
- As a user, I want to be reminded to bring an umbrella for rainy day appointments

### 4. Dynamic Reminder Times
**Goal**: Intelligently calculate when to send notifications

#### Components:
- Smart scheduling algorithm
- Multi-factor calculation (traffic, weather, distance, preparation time)
- User preference learning
- Customizable buffer times

#### User Stories:
- As a user, I want reminders that account for traffic and weather
- As a user, I want different reminder times for different types of tasks
- As a user, I want to set preparation time per task type

## Technical Architecture

### New Packages Needed
```yaml
dependencies:
  # Location
  geolocator: ^10.1.0              # Location tracking
  geocoding: ^2.1.1                # Address <-> coordinates
  
  # Notifications
  flutter_local_notifications: ^16.3.0  # Local notifications
  permission_handler: ^11.1.0      # Permission management
  
  # APIs
  http: ^1.1.0                     # Already added (API calls)
  google_maps_flutter: ^2.5.0      # Map display
  
  # Weather
  weather: ^3.1.1                  # Weather data
  
  # Background tasks
  workmanager: ^0.5.1              # Background job scheduling
```

### Database Schema Updates

#### Add columns to `todos` table:
```sql
ALTER TABLE todos ADD COLUMN IF NOT EXISTS 
  travel_time_minutes INTEGER DEFAULT 0;

ALTER TABLE todos ADD COLUMN IF NOT EXISTS 
  geofence_radius_meters INTEGER DEFAULT 500;

ALTER TABLE todos ADD COLUMN IF NOT EXISTS 
  weather_dependent BOOLEAN DEFAULT FALSE;

ALTER TABLE todos ADD COLUMN IF NOT EXISTS 
  traffic_aware BOOLEAN DEFAULT FALSE;

ALTER TABLE todos ADD COLUMN IF NOT EXISTS 
  preparation_time_minutes INTEGER DEFAULT 15;
```

#### New `notification_settings` table:
```sql
CREATE TABLE notification_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  location_notifications_enabled BOOLEAN DEFAULT TRUE,
  traffic_notifications_enabled BOOLEAN DEFAULT TRUE,
  weather_notifications_enabled BOOLEAN DEFAULT TRUE,
  default_geofence_radius INTEGER DEFAULT 500,
  default_preparation_time INTEGER DEFAULT 15,
  notification_sound TEXT DEFAULT 'default',
  vibration_enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX idx_notification_settings_user ON notification_settings(user_id);
```

## Implementation Steps

### Week 1: Foundation (Days 1-3)
```
Day 1-2: Setup & Permissions
✓ Add required packages to pubspec.yaml
✓ Configure platform-specific permissions (iOS Info.plist, Android Manifest)
✓ Create permission handler service
✓ Implement location permission flow
✓ Implement notification permission flow
✓ Create notification settings UI

Day 3: Database Updates
✓ Create migration script for new columns
✓ Update TodoEntity with new fields
✓ Update todo repository
✓ Create NotificationSettings entity and repository
✓ Test database changes
```

### Week 2: Core Features (Days 4-7)
```
Day 4: Location Service
✓ Create LocationService
✓ Implement current location fetching
✓ Implement geofencing logic
✓ Test location accuracy
✓ Add location picker to todo form

Day 5: Notification Service
✓ Create NotificationService
✓ Setup local notifications
✓ Create notification channels (Android)
✓ Implement notification scheduling
✓ Test notification delivery

Day 6: Weather Integration
✓ Sign up for OpenWeatherMap API
✓ Create WeatherService
✓ Implement weather fetching by location
✓ Add weather display to todo details
✓ Implement weather-based suggestions

Day 7: Traffic Integration
✓ Setup Google Maps API / Apple Maps
✓ Create TrafficService
✓ Implement travel time calculation
✓ Add traffic warnings to notifications
✓ Test with real locations
```

### Week 3: Smart Features (Days 8-10)
```
Day 8: Smart Scheduling
✓ Create SmartSchedulingService
✓ Implement multi-factor reminder calculation
✓ Add algorithm for combining traffic + weather + distance
✓ Create user preference learning system
✓ Test with various scenarios

Day 9: Background Tasks
✓ Setup WorkManager
✓ Implement background location monitoring
✓ Implement periodic traffic/weather checks
✓ Schedule smart notifications
✓ Test background execution

Day 10: UI Updates
✓ Add weather widget to calendar
✓ Add traffic indicator to todos
✓ Create smart notification settings page
✓ Add location map preview
✓ Polish existing UI for new features
```

## File Structure

```
lib/
├── features/
│   ├── smart_planning/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── notification_settings_model.dart
│   │   │   │   ├── weather_model.dart
│   │   │   │   └── traffic_model.dart
│   │   │   ├── repositories/
│   │   │   │   ├── notification_settings_repository_impl.dart
│   │   │   │   ├── weather_repository_impl.dart
│   │   │   │   └── traffic_repository_impl.dart
│   │   │   └── services/
│   │   │       ├── location_service.dart
│   │   │       ├── notification_service.dart
│   │   │       ├── weather_service.dart
│   │   │       ├── traffic_service.dart
│   │   │       └── smart_scheduling_service.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── notification_settings_entity.dart
│   │   │   │   ├── weather_entity.dart
│   │   │   │   └── traffic_entity.dart
│   │   │   └── repositories/
│   │   │       ├── notification_settings_repository.dart
│   │   │       ├── weather_repository.dart
│   │   │       └── traffic_repository.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   ├── notification_settings_page.dart
│   │       │   └── location_picker_page.dart
│   │       ├── widgets/
│   │       │   ├── weather_widget.dart
│   │       │   ├── traffic_indicator.dart
│   │       │   ├── location_map_preview.dart
│   │       │   └── smart_notification_card.dart
│   │       └── providers/
│   │           ├── location_provider.dart
│   │           ├── notification_provider.dart
│   │           ├── weather_provider.dart
│   │           └── traffic_provider.dart
```

## API Keys Required

### 1. OpenWeatherMap
- Sign up: https://openweathermap.org/api
- Free tier: 1,000 calls/day
- Use: Current weather, forecasts, alerts

### 2. Google Maps Platform
- Console: https://console.cloud.google.com/
- APIs needed:
  - Maps SDK for Android/iOS
  - Directions API (for traffic)
  - Geocoding API
- Billing required but generous free tier

### 3. Apple Maps (iOS alternative)
- Built into iOS SDK
- Free to use
- Limited to Apple devices

## Testing Strategy

### Unit Tests
- Location service accuracy
- Notification scheduling logic
- Smart algorithm calculations
- Weather/traffic data parsing

### Integration Tests
- End-to-end notification flow
- Location permission handling
- API integration
- Background task execution

### Manual Testing Checklist
- [ ] Location permissions granted/denied
- [ ] Notifications appear at correct times
- [ ] Weather data updates correctly
- [ ] Traffic conditions affect reminder times
- [ ] Geofencing triggers properly
- [ ] Background tasks run reliably
- [ ] Settings persist correctly
- [ ] Works on both Android and iOS

## Configuration Files

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to send reminders when you're near task locations</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need background location to send timely reminders</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
    <string>processing</string>
</array>
```

## Security & Privacy

### Best Practices
1. **Location Data**
   - Only collect when necessary
   - Clear user consent
   - Don't store historical locations
   - Use minimal accuracy needed

2. **API Keys**
   - Store in environment variables
   - Never commit to git
   - Use Firebase Remote Config for dynamic keys

3. **Notifications**
   - Allow users to disable any notification type
   - Respect quiet hours
   - Follow platform guidelines

## Success Metrics

### Performance
- Notification accuracy: >95% delivered on time
- Location accuracy: <50m error
- Background battery usage: <5% per day
- API call efficiency: <100 calls per user per day

### User Experience
- Permission grant rate: >70%
- Feature adoption: >50% of users enable smart features
- Notification engagement: >30% interaction rate

## Rollout Plan

### Phase 2.1: Location & Notifications (Week 1)
- Basic location services
- Simple notifications
- Beta testing with small group

### Phase 2.2: Weather Integration (Week 2)
- Weather API integration
- Weather-based suggestions
- Expand beta testing

### Phase 2.3: Traffic & Smart Scheduling (Week 3)
- Traffic integration
- Smart reminder algorithm
- Full rollout to all users

## Next Steps

Ready to start implementation? Let's begin with:

1. **Add packages to pubspec.yaml**
2. **Configure platform permissions**
3. **Create permission handler service**
4. **Update database schema**
5. **Build location service**

Would you like me to start implementing Phase 2 now?
