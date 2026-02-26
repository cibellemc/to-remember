import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInAnonymously({
    required String role,
    required String fullName,
  }) async {
    await _supabase.auth.signInAnonymously(
      data: {'full_name': fullName, 'role': role},
    );
  }

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
