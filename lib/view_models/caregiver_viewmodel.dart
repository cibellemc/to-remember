import 'package:flutter/material.dart';
import '../data/repositories/auth_repository.dart';

class CaregiverViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  CaregiverViewModel(this._authRepository) {
    fetchConnectedPatients();
  }

  List<Map<String, dynamic>> _connectedPatients = [];
  List<Map<String, dynamic>> get connectedPatients => _connectedPatients;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchConnectedPatients() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _connectedPatients = await _authRepository.getConnectedPatients();
    } catch (e) {
      _errorMessage = 'Erro ao carregar pacientes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> connectToPatient(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.connectWithCode(code);
      await fetchConnectedPatients();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic>? _selectedPatient;
  Map<String, dynamic>? get selectedPatient => _selectedPatient;

  void selectPatient(Map<String, dynamic>? patient) {
    _selectedPatient = patient;
    notifyListeners();
  }

  Future<void> disconnectFromPatient(String patientId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.disconnectPatient(patientId);
      await fetchConnectedPatients();
    } catch (e) {
      _errorMessage = 'Erro ao desconectar paciente: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
