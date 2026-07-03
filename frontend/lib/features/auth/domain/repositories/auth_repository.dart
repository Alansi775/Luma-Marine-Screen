/// Gate for the hidden admin flow. Nothing about signage playback depends
/// on this — it exists purely so the admin can reach the upload screen.
abstract class AuthRepository {
  bool get isSignedIn;

  String? get currentUserEmail;

  Stream<bool> get authStateChanges;

  /// Throws [AuthException] (see core/errors/app_exception.dart) on
  /// invalid credentials or when Firebase is unavailable.
  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}
