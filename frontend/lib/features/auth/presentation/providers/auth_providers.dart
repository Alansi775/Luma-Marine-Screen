import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/core_providers.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final firebaseAvailable = ref.watch(firebaseAvailableProvider);
  if (!firebaseAvailable) return UnavailableAuthRepository();
  return FirebaseAuthRepository(FirebaseAuth.instance);
}

@Riverpod(keepAlive: true)
Stream<bool> authState(Ref ref) => ref.watch(authRepositoryProvider).authStateChanges;
