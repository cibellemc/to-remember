import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginViewModel(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Wizard State
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Selected Role
  String _selectedRole = 'patient';
  String get selectedRole => _selectedRole;

  // Form Data
  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _patientName = '';
  String get patientName => _patientName;
  String _caregiverType = 'relative';
  String get caregiverType => _caregiverType;
  String _professionalRegistry = '';

  void setRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setName(String value) => _name = value;
  void setEmail(String value) => _email = value;
  void setPassword(String value) => _password = value;
  void setConfirmPassword(String value) => _confirmPassword = value;
  void setPatientName(String value) => _patientName = value;
  void setCaregiverType(String value) {
    _caregiverType = value;
    notifyListeners();
  }

  void setProfessionalRegistry(String value) => _professionalRegistry = value;

  // Login Mode
  bool _isLoginMode = false;
  bool get isLoginMode => _isLoginMode;
  void toggleLoginMode() {
    _isLoginMode = !_isLoginMode;
    _clearErrors();
    notifyListeners();
  }

  // Error States
  String? _nameError;
  String? get nameError => _nameError;

  String? _emailError;
  String? get emailError => _emailError;

  String? _passwordError;
  String? get passwordError => _passwordError;

  String? _confirmPasswordError;
  String? get confirmPasswordError => _confirmPasswordError;

  String? _patientNameError;
  String? get patientNameError => _patientNameError;

  String? _registryError;
  String? get registryError => _registryError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _clearErrors() {
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _patientNameError = null;
    _registryError = null;
    _errorMessage = null;
  }

  // Navigation
  void nextStep() {
    if (_validateStep()) {
      _currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      _clearErrors();
      notifyListeners();
    }
  }

  bool _validateStep() {
    _clearErrors();

    if (_currentStep == 0) return true;

    if (_selectedRole == 'patient') return true;

    if (_selectedRole == 'caregiver' && _currentStep == 1) {
      bool isValid = true;
      if (!_isLoginMode && _name.isEmpty) {
        _nameError = 'Por favor, informe seu nome.';
        isValid = false;
      }
      if (_email.isEmpty || !_email.contains('@')) {
        _emailError = 'Por favor, informe um email válido.';
        isValid = false;
      }
      if (!_isLoginMode) {
        if (_password.length < 6) {
          _passwordError = 'A senha deve ter pelo menos 6 caracteres.';
          isValid = false;
        }
        if (_password != _confirmPassword) {
          _confirmPasswordError = 'As senhas não coincidem.';
          isValid = false;
        }
      } else if (_password.isEmpty) {
        _passwordError = 'Digite sua senha.';
        isValid = false;
      }
      notifyListeners();
      return isValid;
    }

    if (_selectedRole == 'caregiver' && _currentStep == 2) {
      if (_isLoginMode) return true;
      bool isValid = true;
      if (_patientName.trim().isEmpty) {
        _patientNameError = 'Por favor, informe o nome do paciente.';
        isValid = false;
      }
      if (_caregiverType == 'professional' && _professionalRegistry.isEmpty) {
        _registryError = 'Por favor, informe seu registro.';
        isValid = false;
      }
      if (!isValid) notifyListeners();
      return isValid;
    }

    return true;
  }

  Future<bool> finishRegistration() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_selectedRole == 'patient') {
        String displayName = _name.trim();
        if (displayName.isEmpty) {
          displayName = 'Paciente #${Random().nextInt(9999)}';
        }
        await _authRepository.signInAnonymously(
          role: 'patient',
          fullName: displayName,
        );
      } else {
        if (_isLoginMode) {
          await _authRepository.signInWithEmailPassword(
            email: _email.trim(),
            password: _password,
          );
        } else {
          await _authRepository.signUpWithEmailPassword(
            email: _email.trim(),
            password: _password,
            metadata: {
              'full_name': _name.trim(),
              'role': 'caregiver',
              'caregiver_type': _caregiverType,
              'professional_registry': _professionalRegistry,
            },
          );
        }
      }
      return true;
    } catch (e) {
      _errorMessage = _getFriendlyError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _getFriendlyError(Object error) {
    final msg = error.toString();
    if (msg.contains('user_already_exists') ||
        msg.contains('User already registered')) {
      return 'Este email já está cadastrado. Tente fazer login.';
    }
    if (msg.contains('invalid_login_credentials')) {
      return 'Email ou senha incorretos.';
    }
    if (msg.contains('anonymous_provider_disabled')) {
      return 'Login anônimo não está ativado.';
    }
    if (msg.contains('weak_password')) {
      return 'Senha muito fraca.';
    }
    if (msg.contains('invalid_email')) {
      return 'Email inválido.';
    }
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }

  User? get currentUser => _authRepository.currentUser;
}
