import 'dart:math';

/// Utility class for generating and validating family invite codes
class InviteCodeGenerator {
  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 8;

  /// Generate a unique invite code
  /// Format: XXXX-XXXX (8 characters split with dash for readability)
  static String generateCode() {
    final random = Random.secure();
    final code = List.generate(
      _codeLength,
      (index) => _chars[random.nextInt(_chars.length)],
    ).join();

    // Add dash in the middle for readability
    return '${code.substring(0, 4)}-${code.substring(4)}';
  }

  /// Normalize invite code (remove dashes, uppercase)
  static String normalizeCode(String code) {
    return code.replaceAll('-', '').toUpperCase().trim();
  }

  /// Validate invite code format
  static bool isValidFormat(String code) {
    final normalized = normalizeCode(code);
    if (normalized.length != _codeLength) return false;

    // Check all characters are valid
    return normalized.split('').every((char) => _chars.contains(char));
  }

  /// Generate expiration date (7 days from now)
  static DateTime generateExpirationDate() {
    return DateTime.now().add(const Duration(days: 7));
  }

  /// Check if invite code is expired
  static bool isExpired(DateTime? expiresAt) {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt);
  }

  /// Format code for display (with dash)
  static String formatForDisplay(String code) {
    final normalized = normalizeCode(code);
    if (normalized.length != _codeLength) return code;
    return '${normalized.substring(0, 4)}-${normalized.substring(4)}';
  }
}
