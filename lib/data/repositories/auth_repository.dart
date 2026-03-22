import 'dart:math';
import 'dart:async';
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

  // Realtime subscriptions
  StreamSubscription? _patientSub;
  StreamSubscription? _caregiverSub;
  String? _lastSubscribedPatientId;

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
        // 1. Ensure Profile exists for FK safety
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName,
          'role': 'patient',
        });

        // 2. Ensure Patient record exists
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
        _setupRealtimeListeners();
      } catch (e) {
        debugPrint('Error ensuring patient/profile record: $e');
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
            'birthdate': _tryFormatDate(metadata['patient_birthdate']),
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
    _cancelRealtimeListeners();
    await _supabase.auth.signOut();
    _patientProfile = null;
    _connectionCode = null;
    _connectedCaregivers = [];
    _lastSubscribedPatientId = null;
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

    if (_patientProfile != null) {
      _setupRealtimeListeners();
    }

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
    return getActiveCodeForPatient(patient['id']);
  }

  Future<String?> getActiveCodeForPatient(String patientId) async {
    final response = await _supabase
        .from('connection_codes')
        .select('code')
        .eq('patient_id', patientId)
        .isFilter('used_at', null)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .maybeSingle();

    _connectionCode = response?['code'] as String?;
    notifyListeners();
    return _connectionCode;
  }

  Future<String?> generateConnectionCode({String? patientId}) async {
    final user = currentUser;
    if (user == null) return null;

    String? targetPatientId = patientId;
    if (targetPatientId == null) {
      final patient = await _supabase
          .from('patients')
          .select('id')
          .eq('auth_id', user.id)
          .maybeSingle();
      targetPatientId = patient?['id']?.toString();
    }

    if (targetPatientId == null) return null;

    final code = _generateRandomCode(6);
    try {
      await _supabase.from('connection_codes').insert({
        'code': code.toUpperCase(),
        'patient_id': targetPatientId,
        'created_by': user.id,
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(hours: 24))
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

  Future<String> createPatientRecord({
    required String name,
    String? stage,
    String? birthdate,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Não autenticado');

    final response = await _supabase.from('patients').insert({
      'name': name,
      'stage': stage,
      'birth_date': _tryFormatDate(birthdate),
      'auth_id': null, // Caregiver created patient
      'created_by': user.id,
    }).select('id').single();

    final patientId = response['id'].toString();

    // Link current caregiver to this new patient
    await _supabase.from('patient_caregivers').insert({
      'patient_id': patientId,
      'caregiver_id': user.id,
    });

    return patientId;
  }

  Future<void> updatePatientRecord({
    required String patientId,
    required Map<String, dynamic> data,
  }) async {
    if (data.containsKey('birth_date')) {
      data['birth_date'] = _tryFormatDate(data['birth_date']);
    }

    await _supabase
        .from('patients')
        .update(data)
        .eq('id', patientId);

    // Refresh local state if it's the current patient
    if (_patientProfile != null && _patientProfile!['id'] == patientId) {
      await getPatientProfile();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> connectWithCode(String code) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    try {
      final response = await _supabase.rpc(
        'consume_connection_code',
        params: {'p_code': code.trim().toUpperCase()},
      );

      final result = Map<String, dynamic>.from(response);

      if (result['success'] == false) {
        throw Exception(result['message'] ?? 'Falha ao consumir código');
      }

      // If we linked to a patient, return their record
      if (result['type'] == 'patient_linked' && result['patient_id'] != null) {
        final patientId = result['patient_id'].toString();
        final patientResponse = await _supabase
            .from('patients')
            .select()
            .eq('id', patientId)
            .single();
        
        notifyListeners();
        return patientResponse;
      }

      // If the user IS the patient and linked to a caregiver
      if (result['type'] == 'caregiver_linked') {
        await getConnectedCaregivers();
      }

      notifyListeners();
      return null;
    } on PostgrestException catch (e) {
      debugPrint('Supabase/Postgrest Error: ${e.message} - ${e.details}');
      throw Exception(e.message);
    } catch (e) {
      debugPrint('General catch error connecting with code: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getConnectedPatients() async {
    final user = currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('patient_caregivers')
        .select('*, patients (*)')
        .eq('caregiver_id', user.id);

    final List<dynamic> data = response;
    return data.map((item) {
      final patient = Map<String, dynamic>.from(item['patients']);
      patient['added_at'] = item['added_at'];
      patient['relationship'] = item['relationship'];
      return patient;
    }).toList();
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
        .select('*, profiles (*)')
        .eq('patient_id', patient['id']);

    final List<dynamic> data = response;
    _connectedCaregivers = data.map((item) {
      final profile = Map<String, dynamic>.from(item['profiles']);
      profile['added_at'] = item['added_at'];
      profile['relationship'] = item['relationship'];
      return profile;
    }).toList();
    notifyListeners();
    return _connectedCaregivers;
  }

  void _setupRealtimeListeners() {
    final user = currentUser;
    if (user == null) return;

    // 1. Listen to patient record changes (name, stage, birthdate, etc.)
    _patientSub ??= _supabase
        .from('patients')
        .stream(primaryKey: ['id'])
        .eq('auth_id', user.id)
        .listen((data) {
          if (data.isNotEmpty) {
            _patientProfile = data.first;
            notifyListeners();
            
            // If we now have a patient ID, setup the caregiver listener
            final patientId = _patientProfile!['id'].toString();
            if (patientId != _lastSubscribedPatientId) {
               _setupCaregiverListener(patientId);
            }
          }
        });
  }

  void _setupCaregiverListener(String patientId) {
    _caregiverSub?.cancel();
    _lastSubscribedPatientId = patientId;
    
    // 2. Listen to links with caregivers
    _caregiverSub = _supabase
        .from('patient_caregivers')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .listen((_) async {
          // When a new link is added or removed, refresh the caregiver list
          await getConnectedCaregivers();
        });
  }

  void _cancelRealtimeListeners() {
    _patientSub?.cancel();
    _caregiverSub?.cancel();
    _patientSub = null;
    _caregiverSub = null;
    _lastSubscribedPatientId = null;
  }

  @override
  void dispose() {
    _cancelRealtimeListeners();
    super.dispose();
  }

  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      length,
      (_) => chars[Random().nextInt(chars.length)],
    ).join();
  }

  String? _tryFormatDate(String? date) {
    if (date == null || date.isEmpty) return null;
    final trimmed = date.trim();
    try {
      // If already YYYY-MM-DD, return as is
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) return trimmed;

      // Robust handle DD/MM/YYYY (allow various delimiters just in case, but focused on /)
      final parts = trimmed.split(RegExp(r'[/.\-]'));
      if (parts.length == 3) {
        // Try to identify which part is the year (usually 4 digits)
        String day = parts[0];
        String month = parts[1];
        String year = parts[2];

        // Ensure 2 digits for day/month and 4 for year
        if (day.length == 1) day = '0$day';
        if (month.length == 1) month = '0$month';
        
        // If year is the first part (YYYY/MM/DD)
        if (day.length == 4) {
          return '$day-$month-$year';
        }
        
        return '$year-$month-$day';
      }
      return trimmed;
    } catch (e) {
      return trimmed;
    }
  }
}
