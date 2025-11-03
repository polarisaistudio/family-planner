/// Retry helper utility for handling failed operations with exponential backoff
class RetryHelper {
  /// Execute a function with retry logic
  ///
  /// [operation] - The async operation to retry
  /// [maxAttempts] - Maximum number of retry attempts (default: 3)
  /// [delayFactor] - Delay multiplier in milliseconds (default: 1000)
  /// [shouldRetry] - Optional function to determine if error should be retried
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    int delayFactor = 1000,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    dynamic lastError;

    while (attempt < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        attempt++;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        // Don't wait after the last attempt
        if (attempt >= maxAttempts) {
          break;
        }

        // Exponential backoff: wait 1s, 2s, 4s, etc.
        final delay = Duration(milliseconds: delayFactor * (1 << (attempt - 1)));
        await Future.delayed(delay);
      }
    }

    // If we've exhausted all attempts, throw the last error
    throw lastError ?? Exception('Operation failed after $maxAttempts attempts');
  }

  /// Check if an error is retryable (network/timeout errors typically are)
  static bool isRetryableError(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // Common retryable error patterns
    return errorString.contains('timeout') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('unavailable') ||
        errorString.contains('deadline exceeded');
  }
}
