class RetryHandler {
  final int maxRetries;
  final Duration baseDelay;

  const RetryHandler({
    this.maxRetries = 3,
    this.baseDelay = const Duration(seconds: 1),
  });

  Duration getRetryDelay(int attempt) => baseDelay * (attempt + 1) * 2;

  Future<T> execute<T>(Future<T> Function() fn, {String? label}) async {
    var lastError;
    for (var i = 0; i <= maxRetries; i++) {
      try {
        return await fn();
      } catch (e) {
        lastError = e;
        if (i < maxRetries) {
          final delay = baseDelay * (i + 1) * 2; // 1s, 2s, 4s
          if (label != null) {
            print('  ⚠️  $label attempt ${i + 1} failed: $e');
            print('     Retrying in ${delay.inSeconds}s...');
          }
          await Future.delayed(delay);
        }
      }
    }
    throw lastError;
  }
}
