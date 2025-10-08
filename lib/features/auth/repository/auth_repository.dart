import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepository(this._supabaseClient);

  Stream<AuthState> get authStateChanges =>
      _supabaseClient.auth.onAuthStateChange;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _supabaseClient.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await _supabaseClient.auth.signInWithOAuth(OAuthProvider.google);
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }
}
