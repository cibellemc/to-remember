import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository extends ChangeNotifier {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  User? get currentUser => _supabase.auth.currentUser;

  // State properties for reactivity
  Map<String, dynamic>? _patientProfile;
  Map<String, dynamic>? get patientProfile => _patientProfile;

  String? _connectionCode;
  String? get connectionCode => _connectionCode;

  List<Map<String, dynamic>> _connectedCaregivers = [];
  List<Map<String, dynamic>> get connectedCaregivers => _connectedCaregivers;

  Future<void> signInAnonymously({
    required String role,
    required String fullName,
  }) async {
    var user = _supabase.auth.currentUser;

    if (user == null) {
      final response = await _supabase.auth.signInAnonymously(
        data: {'full_name': fullName, 'role': role},
      );
      user = response.user;
    }

    if (user != null && role == 'patient') {
      try {
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
        await getPatientProfile();
      } catch (e) {
        debugPrint('Error ensuring patient record: $e');
      }
    }
    notifyListeners();
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

    if (response.user != null) {
      await ensureProfileAndPatientRecord(metadata);
    }
    notifyListeners();
  }

  Future<void> ensureProfileAndPatientRecord(Map<String, dynamic> metadata) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    try {
      // 1. Ensure Profile
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'full_name': metadata['full_name'] ?? '',
        'email': user.email,
        'role': metadata['caregiver_type'] == 'professional'
            ? 'professional'
            : 'family',
        'crm': metadata['professional_registry'],
        'specialty': metadata['specialty'],
      });

      // 2. Ensure Patient (only if not linking)
      final patientName = metadata['patient_name'] as String?;
      if (patientName != null && patientName.isNotEmpty) {
        // Find if they already have this patient linked to avoid duplicates
        final existingLink = await _supabase
            .from('patient_caregivers')
            .select('patient_id')
            .eq('caregiver_id', user.id)
            .maybeSingle();

        if (existingLink == null) {
          // Caregivers can create patients if RLS allows authenticated users to insert.
          // We ensure auth_id is not set to the caregiver's ID here.
          final patientResponse = await _supabase.from('patients').insert({
            'name': patientName,
            'stage': metadata['patient_stage'],
            'birthdate': metadata['patient_birthdate'],
            'auth_id': null, // Explicitly null for caregiver-created patients
          }).select('id').single();

          final patientId = patientResponse['id'];

          await _supabase.from('patient_caregivers').insert({
            'patient_id': patientId,
            'caregiver_id': user.id,
            'relationship': metadata['relationship'],
          });
        }
      }
    } catch (e) {
      debugPrint('Error in ensureProfileAndPatientRecord: $e');
      rethrow;
    }
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _patientProfile = null;
    _connectionCode = null;
    _connectedCaregivers = [];
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getPatientProfile() async {
    final user = currentUser;
    if (user == null) return null;
    _patientProfile = await _supabase
        .from('patients')
        .select()
        .eq('auth_id', user.id)
        .maybeSingle();
    notifyListeners();
    return _patientProfile;
  }

  Future<String?> getActiveConnectionCode() async {
    final user = currentUser;
    if (user == null) return null;

    final patient = await _supabase
        .from('patients')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (patient == null) return null;

    final response = await _supabase
        .from('connection_codes')
        .select('code')
        .eq('patient_id', patient['id'])
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .maybeSingle();

    _connectionCode = response?['code'] as String?;
    notifyListeners();
    return _connectionCode;
  }

  Future<String?> generateConnectionCode() async {
    final user = currentUser;
    if (user == null) return null;

    final patient = await _supabase
        .from('patients')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (patient == null) return null;

    final existing = await getActiveConnectionCode();
    if (existing != null) return existing;

    final code = _generateRandomCode(6);
    try {
      await _supabase.from('connection_codes').insert({
        'code': code,
        'patient_id': patient['id'],
        'created_by': user.id,
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 10))
            .toIso8601String(),
      });
      _connectionCode = code;
      notifyListeners();
      return code;
    } catch (e) {
      debugPrint('Error generating code: $e');
      return null;
    }
  }

  Future<void> connectWithCode(String code, {String? relationship}) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final codeData = await _supabase
        .from('connection_codes')
        .select('patient_id, expires_at')
        .eq('code', code.toUpperCase())
        .maybeSingle();

    if (codeData == null) {
      throw Exception('Código inválido');
    }

    final expiresAt = DateTime.parse(codeData['expires_at']).toUtc();
    if (expiresAt.isBefore(DateTime.now().toUtc())) {
      throw Exception('Código expirado');
    }

    final patientId = codeData['patient_id'];

    final existing = await _supabase
        .from('patient_caregivers')
        .select()
        .eq('patient_id', patientId)
        .eq('caregiver_id', user.id)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Você já está conectado a este paciente');
    }

    await _supabase.from('patient_caregivers').insert({
      'patient_id': patientId,
      'caregiver_id': user.id,
      'relationship': relationship,
    });
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getConnectedPatients() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('patient_caregivers')
        .select('patients (*)')
        .eq('caregiver_id', user.id);

    final List<dynamic> data = response;
    return data
        .map((item) => item['patients'] as Map<String, dynamic>)
        .toList();
  }

  Future<void> disconnectPatient(String patientId) async {
    final user = currentUser;
    if (user == null) return;

    await _supabase
        .from('patient_caregivers')
        .delete()
        .eq('caregiver_id', user.id)
        .eq('patient_id', patientId);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getConnectedCaregivers() async {
    final user = currentUser;
    if (user == null) return [];

    final patient = await _supabase
        .from('patients')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (patient == null) return [];

    final response = await _supabase
        .from('patient_caregivers')
        .select('profiles (*)')
        .eq('patient_id', patient['id']);

    final List<dynamic> data = response;
    _connectedCaregivers = data
        .map((item) => item['profiles'] as Map<String, dynamic>)
        .toList();
    notifyListeners();
    return _connectedCaregivers;
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (_) => chars[Random().nextInt(chars.length)],
    ).join();
  }
}
