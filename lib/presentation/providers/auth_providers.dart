import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friend_tracker/data/services/firestore_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

class AuthNotifier extends AsyncNotifier<void> {
  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);

  @override
  Future<void> build() async {}

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async => _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final taken = await FirestoreService().isDisplayNameTaken(displayName);
      if (taken) {
        throw FirebaseAuthException(
          code: 'display-name-taken',
          message: 'That name is already in use.',
        );
      }
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(displayName);
    });
  }

  Future<void> updateDisplayName(String newName) async {
    final trimmed = newName.trim();
    final user = _auth.currentUser;
    if (user == null) return;
    final taken = await FirestoreService().isDisplayNameTaken(trimmed);
    if (taken) {
      throw FirebaseAuthException(
        code: 'display-name-taken',
        message: 'That name is already in use.',
      );
    }
    await user.updateDisplayName(trimmed);
    await FirestoreService().updateDisplayNameInProfile(user.uid, trimmed);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);
