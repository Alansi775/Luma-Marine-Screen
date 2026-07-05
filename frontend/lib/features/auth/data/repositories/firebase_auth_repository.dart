import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/app_exception.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  bool get isSignedIn => _auth.currentUser != null;

  @override
  String? get currentUserEmail => _auth.currentUser?.email;

  @override
  Stream<bool> get authStateChanges => _auth.authStateChanges().map((user) => user != null);

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e), cause: e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'E-posta veya şifre hatalı.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Daha sonra tekrar deneyin.';
      default:
        return e.message ?? 'Giriş başarısız.';
    }
  }
}

/// Used when Firebase failed to initialize — sign-in must fail clearly
/// rather than throw a confusing "no Firebase App" error from the SDK.
class UnavailableAuthRepository implements AuthRepository {
  @override
  bool get isSignedIn => false;

  @override
  String? get currentUserEmail => null;

  @override
  Stream<bool> get authStateChanges => Stream.value(false);

  @override
  Future<void> signIn({required String email, required String password}) async {
    throw const AuthException('Firebase şu anda kullanılamıyor, giriş yapılamıyor.');
  }

  @override
  Future<void> signOut() async {}
}
