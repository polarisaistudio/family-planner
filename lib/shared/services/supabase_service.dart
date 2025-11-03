import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_config.dart';

/// Service to initialize and provide Supabase client
class SupabaseService {
  static SupabaseClient? _client;

  /// Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      anonKey: SupabaseConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first',
      );
    }
    return _client!;
  }
}
