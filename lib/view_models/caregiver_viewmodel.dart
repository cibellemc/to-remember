import 'dart:async';
import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

class CaregiverViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  AuthRepository get authRepository => _authRepository;

  CaregiverViewModel(this._authRepository) {
    fetchConnectedPatients();
  }

  List<Map<String, dynamic>> _connectedPatients = [];
  List<Map<String, dynamic>> get connectedPatients => _connectedPatients;

  List<Map<String, dynamic>> get activePatients =>
      _connectedPatients.where((p) => p['status'] == 'active').toList();

  List<Map<String, dynamic>> get inactivePatients =>
      _connectedPatients.where((p) => p['status'] == 'inactive').toList();

  List<Map<String, dynamic>> _patientCaregivers = [];
  List<Map<String, dynamic>> get patientCaregivers => _patientCaregivers;

  List<Map<String, dynamic>> _patientGameSessions = [];
  List<Map<String, dynamic>> get patientGameSessions => _patientGameSessions;

  List<Map<String, dynamic>> _patientGameProgressList = [];
  List<Map<String, dynamic>> get patientGameProgressList => _patientGameProgressList;

  bool _isLoadingGameData = false;
  bool get isLoadingGameData => _isLoadingGameData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  Timer? _errorTimer;

  Future<void> fetchConnectedPatients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _connectedPatients = await _authRepository.getConnectedPatients();
      
      // Update selected patient to reflect status change
      if (_selectedPatient != null) {
        final updated = _connectedPatients.firstWhere(
          (p) => p['id'] == _selectedPatient!['id'],
          orElse: () => _selectedPatient!,
        );
        _selectedPatient = updated;
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar pacientes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> connectToPatient(String code, String? suffix, {String? targetPatientId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final patient = await _authRepository.connectWithCode(
        code, 
        patientSuffix: suffix,
        targetPatientId: targetPatientId,
      );
      await fetchConnectedPatients();
      return patient;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _selectedPatient;
  Map<String, dynamic>? get selectedPatient => _selectedPatient;

  void selectPatient(Map<String, dynamic>? patient) {
    _selectedPatient = patient;
    if (patient != null) {
      final patientId = patient['id'].toString();
      fetchPatientCaregivers(patientId);
      fetchPatientGameData(patientId);
    } else {
      _patientCaregivers = [];
      _patientGameSessions = [];
      _patientGameProgressList = [];
    }
    notifyListeners();
  }

  Future<void> fetchPatientCaregivers(String patientId) async {
    try {
      _patientCaregivers = await _authRepository.getCaregiversForPatient(patientId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching patient caregivers: $e');
    }
  }

  Future<void> fetchPatientGameData(String patientId) async {
    _isLoadingGameData = true;
    notifyListeners();
    try {
      _patientGameSessions = await _authRepository.getGameSessions(patientId);
      _patientGameProgressList = await _authRepository.getPatientAllGameProgress(patientId);
    } catch (e) {
      debugPrint('Error fetching patient game data: $e');
    } finally {
      _isLoadingGameData = false;
      notifyListeners();
    }
  }

  Future<void> disconnectFromPatient(String patientId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.disconnectPatient(patientId);
      await fetchConnectedPatients();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reactivatePatient({
    required String patientId,
    required String code,
    String? suffix,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.connectWithCode(
        code,
        patientSuffix: suffix,
      );
      await fetchConnectedPatients();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createNewPatient({
    required String name,
    String? stage,
    String? birthdate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final patientId = await _authRepository.createPatientRecord(
        name: name,
        stage: stage,
        birthdate: birthdate,
      );
      await fetchConnectedPatients();
      return patientId;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      debugPrint('CaregiverViewModel Error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getActiveCodeForPatient(String patientId) async {
    try {
      return await _authRepository.getActiveCodeForPatient(patientId);
    } catch (e) {
      debugPrint('Error fetching code: $e');
      return null;
    }
  }

  Future<String?> refreshCodeForPatient(String patientId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final code = await _authRepository.generateConnectionCode(patientId: patientId);
      return code;
    } catch (e) {
      _errorMessage = 'Erro ao gerar código: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> getPatientFromCode(String code, String suffix) async {
    return _authRepository.getPatientFromCode(code, suffix);
  }

  Future<void> updatePatient({
    required String patientId,
    required String name,
    String? stage,
    String? birthdate,
    bool? isProfileComplete,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'stage': stage,
        'birth_date': birthdate,
      };
      if (isProfileComplete != null) {
        updateData['is_profile_complete'] = isProfileComplete;
      }

      await _authRepository.updatePatientRecord(
        patientId: patientId,
        data: updateData,
      );
      await fetchConnectedPatients();
      // Update selected patient if it's the one we just edited
      if (_selectedPatient != null && _selectedPatient!['id'] == patientId) {
        _selectedPatient = _connectedPatients.firstWhere((p) => p['id'] == patientId);
      }
    } catch (e) {
      _errorMessage = 'Erro ao atualizar paciente: $e';
      debugPrint('CaregiverViewModel Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setErrorMessage(String? msg) {
    _errorMessage = msg;
    notifyListeners();

    _errorTimer?.cancel();
    if (msg != null) {
      _errorTimer = Timer(const Duration(seconds: 5), () {
        clearError();
      });
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
    _errorTimer?.cancel();
  }
}
