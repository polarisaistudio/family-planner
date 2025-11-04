import 'package:flutter/foundation.dart';

/// Platform detection service
class PlatformService {
  /// Check if we should use REST API instead of Firebase SDK
  /// Use REST on iOS to avoid gRPC issues with Xcode 16
  static bool get useRestApi {
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Check if we should use Firebase SDK
  static bool get useFirebaseSDK {
    return !useRestApi;
  }
}
