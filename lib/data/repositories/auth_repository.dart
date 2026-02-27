import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;

  Future<void> signInAnonymously({
    required String role,
    required String fullName,
  }) async {
    // 1. Check if already logged in
    var user = _supabase.auth.currentUser;

    if (user == null) {
      final response = await _supabase.auth.signInAnonymously(
        data: {'full_name': fullName, 'role': role},
      );
      user = response.user;
    }

    // 2. Ensure patient record exists in the database
    if (user != null && role == 'patient') {
      try {
        // Check if record exists first to avoid "create only on first login" issues
        final existing = await _supabase
            .from('patients')
            .select()
            .eq('auth_id', user.id)
            .maybeSingle();

        if (existing == null) {
          await _supabase.from('patients').insert({
            'name': fullName,
            'auth_id': user.id,
          });
        }
      } catch (e) {
        // Log error but don't necessarily block if user is already in Auth
        debugPrint('Error ensuring patient record: $e');
      }
    }
  }

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
    required Map<String, dynamic> metadata,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );

    final user = response.user;
    if (user != null) {
      try {
        await _supabase.from('profiles').insert({
          'id': user.id,
          'full_name': metadata['full_name'] ?? '',
          'email': email,
          'role': metadata['caregiver_type'] == 'professional'
              ? 'professional'
              : 'family',
          'crm': metadata['professional_registry'],
          'specialty': metadata['specialty'],
        });
      } catch (e) {
        rethrow;
      }
    }
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

  // --- Patient Profile & Connection Codes ---

  Future<Map<String, dynamic>?> getPatientProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return await _supabase
        .from('patients')
        .select()
        .eq('auth_id', user.id)
        .maybeSingle();
  }

  Future<String?> getActiveConnectionCode() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('connection_codes')
        .select('code')
        .eq('patient_id', user.id)
        .gt('expires_at', DateTime.now().toIso8601String())
        .maybeSingle();

    return response?['code'] as String?;
  }

  Future<String?> generateConnectionCode() async {
    final user = currentUser;
    if (user == null) return null;

    // First check if one already exists
    final existing = await getActiveConnectionCode();
    if (existing != null) return existing;

    final code = _generateRandomCode(6);
    try {
      await _supabase.from('connection_codes').insert({
        'code': code,
        'patient_id': user.id,
        'created_by': user.id,
        'expires_at': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      });
      return code;
    } catch (e) {
      debugPrint('Error generating code: $e');
      return null;
    }
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = DateTime.now().millisecondsSinceEpoch;
    // Simple but enough for this context
    return List.generate(
      length,
      (index) => chars[(index + rand) % chars.length],
    ).join();
  }
}
