import 'package:firebase_auth/firebase_auth.dart';

import '../models/users.dart';

class AuthService {
  AuthService({FirebaseAuth? auth}) : _authInstance = auth;

  final FirebaseAuth? _authInstance;

  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<AppUser> register(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'missing-user',
        message: 'Firebase did not return the newly registered user.',
      );
    }

    final user = AppUser.fromFirebaseUser(firebaseUser);
    await firebaseUser.reload();
    return user;
  }

  Future<void> signOut() => _auth.signOut();
}

String authErrorMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Something went wrong. Please try again.';
  }

  final code = error.code.toLowerCase();
  final details = error.message?.toLowerCase() ?? '';

  // On Android, Firebase sometimes wraps this backend response in an
  // `unknown` exception instead of exposing `configuration-not-found` as the
  // exception code.
  if (code.contains('configuration-not-found') ||
      details.contains('configuration_not_found') ||
      details.contains('configuration not found')) {
    return 'Email/password sign-in is not enabled in Firebase. Enable it in '
        'Firebase Console > Authentication > Sign-in method.';
  }

  return switch (code) {
    'invalid-email' => 'Please enter a valid email address.',
    'email-already-in-use' =>
      'This email is already registered. Please log in.',
    'weak-password' => 'Choose a stronger password with at least 6 characters.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-login-credentials' => 'The email or password is incorrect.',
    'user-disabled' => 'This account has been disabled.',
    'too-many-requests' => 'Too many attempts. Please try again later.',
    'network-request-failed' =>
      'Firebase could not be reached. Check the device Wi-Fi and try again.',
    'operation-not-allowed' || 'configuration-not-found' =>
      'Email/password sign-in is not enabled in Firebase.',
    'missing-user' => 'Firebase created no user. Please try again.',
    _ => 'Unable to authenticate. Please try again.',
  };
}
