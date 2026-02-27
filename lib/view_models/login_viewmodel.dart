import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginViewModel(this._authRepository);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  //Wizard State
  int _currentStep = 0;
  int get currentStep => _currentStep;

  // Selected Role
  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  // Form Data
  String _name = '';
  String get name => _name;
  String _email = '';
  String get email => _email;
  String _password = '';
  String get password => _password;
  String _confirmPassword = '';
  String get confirmPassword => _confirmPassword;
  String _patientName = '';
  String get patientName => _patientName;
  String? _caregiverType;
  String? get caregiverType => _caregiverType;
  String _professionalRegistry = '';
  String get professionalRegistry => _professionalRegistry;
  String _specialty = '';
  String get specialty => _specialty;

  void setRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    _confirmPasswordError = null;
    notifyListeners();
  }

  void setPatientName(String value) {
    _patientName = value;
    notifyListeners();
  }

  void setCaregiverType(String value) {
    _caregiverType = value;
    notifyListeners();
  }

  void setProfessionalRegistry(String value) {
    _professionalRegistry = value;
    notifyListeners();
  }

  void setSpecialty(String value) {
    _specialty = value;
    notifyListeners();
  }

  // Login Mode
  bool? _isLoginMode;
  bool get isLoginMode => _isLoginMode ?? false;
  bool? get isLoginModeRaw => _isLoginMode;

  void setLoginMode(bool value) {
    if (_isLoginMode != value) {
      _isLoginMode = value;
      _clearErrors();
      notifyListeners();
    }
  }

  void toggleLoginMode() {
    _isLoginMode = !isLoginMode;
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
    if (validateCurrentStep()) {
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

  bool validateCurrentStep() {
    _clearErrors();

    if (_currentStep == 0) {
      return _selectedRole != null;
    }

    if (_selectedRole == 'patient') return true;

    // Step 1: First time access? (Sim/Não)
    if (_selectedRole == 'caregiver' && _currentStep == 1) {
      return _isLoginMode != null;
    }

    // Step 2: Caregiver Profile (Familiar/Médico) (Only if Sim)
    if (_selectedRole == 'caregiver' && _currentStep == 2 && !isLoginMode) {
      return _caregiverType != null;
    }

    // Step 3 (or 2 if login): Basic Info + Professional Info if needed
    if (_selectedRole == 'caregiver' &&
        ((!isLoginMode && _currentStep == 3) ||
            (isLoginMode && _currentStep == 2))) {
      bool isValid = true;
      if (!isLoginMode && _name.trim().isEmpty) {
        _nameError = 'Por favor, informe seu nome.';
        isValid = false;
      }
      if (_email.trim().isEmpty || !_email.contains('@')) {
        _emailError = 'Por favor, informe um email válido.';
        isValid = false;
      }
      if (!isLoginMode) {
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

      return isValid;
    }

    // Step 4: Professional info
    if (_selectedRole == 'caregiver' &&
        !isLoginMode &&
        _caregiverType == 'professional' &&
        _currentStep == 4) {
      bool isValid = true;
      if (_professionalRegistry.trim().isEmpty) {
        _registryError = 'Por favor, informe seu CRM/Registro.';
        isValid = false;
      }
      return isValid;
    }

    return true;
  }

  bool get canSubmit {
    if (_selectedRole == 'patient') return true;
    if (_isLoginMode == true) {
      return _email.trim().isNotEmpty && _password.isNotEmpty;
    } else {
      bool filled =
          _name.trim().isNotEmpty &&
          _email.trim().isNotEmpty &&
          _password.isNotEmpty &&
          _confirmPassword.isNotEmpty;
      if (_caregiverType == 'professional') {
        filled = filled && _professionalRegistry.trim().isNotEmpty;
      }
      return filled;
    }
  }

  Future<bool> finishRegistration() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_selectedRole == 'patient') {
        // Reuse session if exists, otherwise sign in
        final currentUser = _authRepository.currentUser;
        if (currentUser == null) {
          String displayName = _name.trim();
          if (displayName.isEmpty) {
            displayName = 'Paciente #${Random().nextInt(9999)}';
          }
          await _authRepository.signInAnonymously(
            role: 'patient',
            fullName: displayName,
          );
        }
      } else {
        if (isLoginMode) {
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
              'specialty': _specialty,
              'patient_name': _patientName.trim(),
            },
          );
        }
      }
      return true;
    } catch (e) {
      debugPrint('Registration Error: $e');
      _errorMessage = _getFriendlyError(e);
      // If none of the friendly errors matched, show the raw one for debugging
      if (_errorMessage == 'Ocorreu um erro inesperado. Tente novamente.') {
        _errorMessage = 'Erro: ${e.toString()}';
      }
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
