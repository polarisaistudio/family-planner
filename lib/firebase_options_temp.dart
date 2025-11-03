// Temporary Firebase configuration
// You MUST add a Web App in Firebase Console to get the real apiKey and appId
// Go to: https://console.firebase.google.com/project/family-planner-86edd/settings/general
// Click the Web icon </> to add a web app and get the real values

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Get the real apiKey and appId by adding a Web App in Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'TEMPORARY_KEY_NEEDS_TO_BE_REPLACED',  // ← MUST GET FROM FIREBASE CONSOLE
    appId: '1:751569532309:web:TEMP_APP_ID',        // ← MUST GET FROM FIREBASE CONSOLE
    messagingSenderId: '751569532309',              // ✅ We have this
    projectId: 'family-planner-86edd',              // ✅ We have this
    authDomain: 'family-planner-86edd.firebaseapp.com',  // ✅ We have this
    storageBucket: 'family-planner-86edd.appspot.com',   // ✅ We have this
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'NEEDS_ANDROID_API_KEY',
    appId: '1:751569532309:android:TEMP_APP_ID',
    messagingSenderId: '751569532309',
    projectId: 'family-planner-86edd',
    storageBucket: 'family-planner-86edd.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'NEEDS_IOS_API_KEY',
    appId: '1:751569532309:ios:TEMP_APP_ID',
    messagingSenderId: '751569532309',
    projectId: 'family-planner-86edd',
    storageBucket: 'family-planner-86edd.appspot.com',
    iosClientId: 'NEEDS_IOS_CLIENT_ID',
    iosBundleId: 'com.example.familyPlanner',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'NEEDS_MACOS_API_KEY',
    appId: '1:751569532309:macos:TEMP_APP_ID',
    messagingSenderId: '751569532309',
    projectId: 'family-planner-86edd',
    storageBucket: 'family-planner-86edd.appspot.com',
    iosClientId: 'NEEDS_MACOS_CLIENT_ID',
    iosBundleId: 'com.example.familyPlanner',
  );
}
