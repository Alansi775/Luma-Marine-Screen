/// Base type for expected, handleable failures within the app.
///
/// Distinguishing these from arbitrary [Exception]s lets callers decide
/// what's safe to swallow-and-log (e.g. sync failures must never crash
/// playback) versus what indicates a real programming error.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message'
      '${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when a network-dependent operation (Firestore/Storage) fails.
/// Callers in the sync path must catch this and degrade gracefully.
final class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause});
}

/// Thrown when local disk access (database, video files, logs) fails.
final class CacheException extends AppException {
  const CacheException(super.message, {super.cause});
}

/// Thrown when a Firestore/Storage document is missing or malformed.
final class DataFormatException extends AppException {
  const DataFormatException(super.message, {super.cause});
}

/// Thrown when admin sign-in fails (wrong credentials, Firebase
/// unavailable, etc). Only the admin-facing screens should ever see this.
final class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}
