import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository extends ChangeNotifier {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase) {
    // Se já existe usuário na inicialização (sessão persistida), marca como visto.
    if (_supabase.auth.currentUser != null) {
      _hasHadSession = true;
    }
  }

  User? get currentUser => _supabase.auth.currentUser;

  // Flag que indica se já houve uma sessão autenticada nesta execução do app.
  // Isso diferencia "nunca entrou" (mostrar onboarding) de "fez logout" (mostrar login).
  bool _hasHadSession = false;
  bool get hasHadSession => _hasHadSession;

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
  StreamSubscription? _codeSub;
  String? _lastSubscribedPatientId;
  String? _roleOverride;
  String? _emulatedPatientId;
  String? get roleOverride => _roleOverride;
  String? get emulatedPatientId => _emulatedPatientId;

  String? get currentRole => _roleOverride ?? currentUser?.userMetadata?['role'] as String?;


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
          // Extract suffix from name if it follows the pattern "#1234"
          String? suffix;
          final match = RegExp(r'#(\d{4})').firstMatch(fullName);
          if (match != null) {
            suffix = match.group(1);
          }

          await _supabase.from('patients').insert({
            'name': fullName,
            'auth_id': user.id,
            'linking_suffix': suffix,
          });
        }
        await getPatientProfile();
        _setupRealtimeListeners();
      } catch (e) {
        debugPrint('Error ensuring patient/profile record: $e');
      }
    }
    _hasHadSession = true;
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
      _hasHadSession = true;
      await ensureProfileAndPatientRecord(metadata);
    }
    notifyListeners();
  }

  Future<void> ensureProfileAndPatientRecord(
    Map<String, dynamic> metadata,
  ) async {
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
          final patientResponse = await _supabase
              .from('patients')
              .insert({
                'name': patientName,
                'stage': metadata['patient_stage'],
                'birth_date': _tryFormatDate(metadata['patient_birthdate']),
                'auth_id':
                    null, // Explicitly null for caregiver-created patients
              })
              .select('id')
              .single();

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
    _hasHadSession = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    _cancelRealtimeListeners();
    await _supabase.auth.signOut();
    _patientProfile = null;
    _connectionCode = null;
    _connectedCaregivers = [];
    _lastSubscribedPatientId = null;
    _roleOverride = null;
    _emulatedPatientId = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getPatientProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final queryId = _emulatedPatientId ?? user.id;
    final queryColumn = _emulatedPatientId != null ? 'id' : 'auth_id';

    _patientProfile = await _supabase
        .from('patients')
        .select()
        .eq(queryColumn, queryId)
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

    if (_emulatedPatientId != null) {
      return getActiveCodeForPatient(_emulatedPatientId!);
    }

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
        .limit(1)
        .maybeSingle();

    _connectionCode = response?['code'] as String?;
    notifyListeners();
    return _connectionCode;
  }

  Future<String?> generateConnectionCode({String? patientId}) async {
    final user = currentUser;
    if (user == null) return null;

    String? targetPatientId = patientId ?? _emulatedPatientId;
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

    final response = await _supabase
        .from('patients')
        .insert({
          'name': name,
          'stage': stage,
          'birth_date': _tryFormatDate(birthdate),
          'auth_id': null, // Caregiver created patient
          'created_by': user.id,
          'is_profile_complete': (name.isNotEmpty && stage != null),
        })
        .select('id')
        .single();

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

    // Automatically set profile complete if name and stage exist
    if (data.containsKey('name') || data.containsKey('stage')) {
      // We don't have the full record here, but we can peek or let the trigger handle it.
      // For now, if both are set in the update, we can mark it.
      // However, a safer way is to let the dashboard check the fields.
      // But let's check if we have enough to mark it.
      if (data['name'] != null && data['stage'] != null) {
        data['is_profile_complete'] = true;
      }
    }

    await _supabase.from('patients').update(data).eq('id', patientId);

    // Refresh local state if it's the current patient
    if (_patientProfile != null && _patientProfile!['id'] == patientId) {
      await getPatientProfile();
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getPatientFromCode(String code, String suffix) async {
    final sanitizedCode = code.trim().toUpperCase().replaceAll(' ', '');
    try {
      final response = await _supabase.rpc(
        'get_patient_by_code',
        params: {
          'p_code': sanitizedCode,
          'p_patient_suffix': suffix.trim(),
        },
      ).maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Error getting patient from code: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> connectWithCode(
    String code, {
    String? patientSuffix,
    String? targetPatientId,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    try {
      final sanitizedCode = code.trim().toUpperCase().replaceAll(' ', '');
      final params = {
        'p_code': sanitizedCode,
        'p_patient_suffix': patientSuffix?.trim(),
        'p_target_patient_id': targetPatientId,
      };

      final response = await _supabase.rpc(
        'consume_connection_code',
        params: params,
      );

      final result = Map<String, dynamic>.from(response);

      if (result['success'] == false) {
        throw Exception(result['message'] ?? 'Falha ao consumir código');
      }

      // Return patient record for both link types (as long as we have a patientId)
      if ((result['type'] == 'patient_linked' || result['type'] == 'caregiver_linked') && 
          result['patient_id'] != null) {
        final patientId = result['patient_id'].toString();
        final patientResponse = await _supabase
            .from('patients')
            .select()
            .eq('id', patientId)
            .single();

        notifyListeners();
        return patientResponse;
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
      patient['status'] = item['status'] ?? 'active'; // Included status
      return patient;
    }).toList();
  }

  Future<void> disconnectPatient(String patientId) async {
    final user = currentUser;
    if (user == null) return;

    // Check if this is the last active caregiver for this patient
    final response = await _supabase
        .from('patient_caregivers')
        .select('caregiver_id')
        .eq('patient_id', patientId)
        .eq('status', 'active');
    
    final count = (response as List).length;
    
    if (count <= 1) {
      throw Exception('Não é possível sair. Este paciente precisa de pelo menos um cuidador ativo. Conecte outro cuidador primeiro.');
    }

    await _supabase
        .from('patient_caregivers')
        .update({
          'status': 'inactive',
          'deactivated_at': DateTime.now().toIso8601String(),
        })
        .eq('caregiver_id', user.id)
        .eq('patient_id', patientId);
    notifyListeners();
  }

  Future<void> activatePatient(String patientId) async {
    final user = currentUser;
    if (user == null) return;

    await _supabase
        .from('patient_caregivers')
        .update({
          'status': 'active',
          'reactivated_at': DateTime.now().toIso8601String(),
        })
        .eq('caregiver_id', user.id)
        .eq('patient_id', patientId);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getConnectedCaregivers() async {
    final user = currentUser;
    if (user == null) return [];

    if (_emulatedPatientId != null) {
      return getCaregiversForPatient(_emulatedPatientId!);
    }

    final patient = await _supabase
        .from('patients')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle();

    if (patient == null) return [];

    return getCaregiversForPatient(patient['id'].toString());
  }

  Future<List<Map<String, dynamic>>> getCaregiversForPatient(
    String patientId,
  ) async {
    final response = await _supabase
        .from('patient_caregivers')
        .select('*, profiles (*)')
        .eq('patient_id', patientId);

    final List<dynamic> data = response;
    final list = data.map((item) {
      final profile = Map<String, dynamic>.from(item['profiles']);
      // Normalize name for UI consistency
      profile['name'] = profile['full_name'];
      profile['added_at'] = item['added_at'];
      profile['relationship'] = item['relationship'];
      profile['is_admin'] = item['is_admin'];
      profile['status'] = item['status'] ?? 'active';
      return profile;
    }).toList();

    // If we're updating for the current patient profile, update the local state
    if (_patientProfile != null && _patientProfile!['id'] == patientId) {
      _connectedCaregivers = list;
      notifyListeners();
    }

    return list;
  }

  void _setupRealtimeListeners() {
    final user = currentUser;
    if (user == null) return;

    final queryId = _emulatedPatientId ?? user.id;
    final queryColumn = _emulatedPatientId != null ? 'id' : 'auth_id';

    // 1. Listen to patient record changes (name, stage, birthdate, etc.)
    _patientSub ??= _supabase
        .from('patients')
        .stream(primaryKey: ['id'])
        .eq(queryColumn, queryId)
        .listen((data) {
          if (data.isNotEmpty) {
            _patientProfile = data.first;
            notifyListeners();

            // If we now have a patient ID, setup the caregiver listener
            final patientId = _patientProfile!['id'].toString();
            if (patientId != _lastSubscribedPatientId) {
              _setupCaregiverListener(patientId);
              _setupCodeListener(patientId);
            }
          } else {
            // Se o dado sumiu, pode ter sido um merge (deletou o temporário).
            // Tentamos recarregar para ver se encontramos o novo registro vinculado ao auth_id.
            getPatientProfile();
          }
        });
  }

  void _setupCaregiverListener(String patientId) {
    _caregiverSub?.cancel();
    _lastSubscribedPatientId = patientId;

    // 2. Listen to links with caregivers
    _caregiverSub = _supabase
        .from('patient_caregivers')
        .stream(primaryKey: ['patient_id', 'caregiver_id'])
        .eq('patient_id', patientId)
        .listen((_) async {
          // When a new link is added or removed, refresh the caregiver list
          await getConnectedCaregivers();
        });
  }

  void _setupCodeListener(String patientId) {
    _codeSub?.cancel();
    // NOTE: connection_codes uses 'code' as primary key (not 'id')
    _codeSub = _supabase
        .from('connection_codes')
        .stream(primaryKey: ['code'])
        .eq('patient_id', patientId)
        .listen((data) async {
          if (data.isNotEmpty) {
            // Find the latest active (unused, non-expired) code
            final now = DateTime.now().toUtc();
            final activeCodes = data.where((c) {
              if (c['used_at'] != null) return false;
              final expiresAt = c['expires_at'];
              if (expiresAt == null) return true;
              return DateTime.tryParse(expiresAt.toString())?.isAfter(now) ?? false;
            }).toList();

            if (activeCodes.isNotEmpty) {
              activeCodes.sort(
                (a, b) => b['created_at'].compareTo(a['created_at']),
              );
              _connectionCode = activeCodes.first['code'];
              notifyListeners();
            } else {
              // All visible codes are used — the new rotated code may not have
              // arrived in the stream yet. Do a fresh DB fetch to pick it up.
              await getActiveCodeForPatient(patientId);
            }
          } else {
            // No codes in stream at all — fetch from DB
            await getActiveCodeForPatient(patientId);
          }
        });
  }

  void _cancelRealtimeListeners() {
    _patientSub?.cancel();
    _caregiverSub?.cancel();
    _codeSub?.cancel();
    _patientSub = null;
    _caregiverSub = null;
    _codeSub = null;
    _lastSubscribedPatientId = null;
  }

  @override
  void dispose() {
    _cancelRealtimeListeners();
    super.dispose();
  }

  String? formatDateBR(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return null;
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return isoDate;
    }
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

  // Security PIN and Role Override Methods

  void setRoleOverride(String? role, {String? patientId}) {
    _roleOverride = role;
    _emulatedPatientId = patientId;
    
    // Clear profile so it can be reloaded for the right context
    _patientProfile = null;
    _cancelRealtimeListeners();
    
    notifyListeners();
  }

  Future<void> updateSecurityPin(String pin) async {
    final user = currentUser;
    if (user == null) throw Exception('Não autenticado');

    await _supabase.from('profiles').update({'security_pin': pin}).eq('id', user.id);
  }

  Future<bool> verifySecurityPin(String pin) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final response = await _supabase.rpc('verify_security_pin', params: {'p_pin': pin});
      return response as bool;
    } catch (e) {
      debugPrint('Error verifying PIN: $e');
      return false;
    }
  }
}
