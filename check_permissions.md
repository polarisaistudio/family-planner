# Permission Troubleshooting Guide for iOS

## Why permissions don't show in Settings:

On iOS, **permissions only appear in the Settings app AFTER you've been prompted for them in the app**.

## Steps to grant permissions:

1. **Open the Family Planner app on your iPhone**
   
2. **Navigate to the permissions screen in the app** (usually in Settings/Profile section)
   
3. **Tap "Grant Permissions" or similar button**
   - This will trigger iOS permission dialogs
   - You should see popups asking for:
     - Location access
     - Notifications
     - Background location (after granting regular location)

4. **If permission dialogs don't appear:**
   - You may have already denied them
   - Go to iPhone Settings > Family Planner
   - Look for:
     - Location → Set to "While Using the App" or "Always"
     - Notifications → Enable
     
5. **If permissions still don't show in Settings:**
   - Uninstall the app completely
   - Reinstall from Xcode/Flutter
   - This resets all permission states
   
## Current Permission Requirements:

✅ Location (When In Use) - For task location features
✅ Location (Always) - For background reminders  
✅ Notifications - For task reminders
✅ Background App Refresh - For location-based alerts

## Debug: Check if the app is requesting permissions

The app should show permission dialogs when you:
- First create a location-based task
- Enable smart planning features
- Tap any "Grant Permissions" button

If dialogs still don't appear, there may be a code issue.
