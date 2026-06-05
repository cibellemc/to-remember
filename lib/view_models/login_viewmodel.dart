import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repositories/auth_repository.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginViewModel(this._authRepository);

  AuthRepository get authRepository => _authRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  //Wizard State
  int _currentStep = 0;
  int get currentStep => _currentStep;

  int get totalSteps {
    if (_selectedRole == 'patient') return 1;
    if (isLoginMode) return 3; // Role (0), Mode (1), LoginInfo (2) (not used for Caregiver anymore)
    if (_selectedRole == 'caregiver') {
      if (_caregiverType == 'professional') return 5; // Role(0), Type(1), Basic(2), Prof(3), PIN(4)
      return 4; // Role(0), Type(1), Basic(2), PIN(3)
    }
    return 4; // Default safety
  }

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
  String _securityPin = '';
  String get securityPin => _securityPin;

  String _patientBirthdate = '';
  String get patientBirthdate => _patientBirthdate;
  String? _patientStage;
  String? get patientStage => _patientStage;

  int? _connectionChoice; // 1: Link, 2: New
  int? get connectionChoice => _connectionChoice;

  String _connectionCode = '';
  String get connectionCode => _connectionCode;

  void setRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }

  void setPatientBirthdate(String value) {
    _patientBirthdate = value;
    notifyListeners();
  }

  void setPatientStage(String? value) {
    _patientStage = value;
    notifyListeners();
  }

  void setConnectionChoice(int? value) {
    _connectionChoice = value;
    notifyListeners();
  }

  void setName(String value) {
    _name = value;
    _nameError = null;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    _emailError = null;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _passwordError = null;
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    _confirmPasswordError = null;
    notifyListeners();
  }

  void setPatientName(String value) {
    _patientName = value;
    _patientNameError = null;
    notifyListeners();
  }

  void setCaregiverType(String value) {
    _caregiverType = value;
    notifyListeners();
  }

  void setProfessionalRegistry(String value) {
    _professionalRegistry = value;
    _registryError = null;
    notifyListeners();
  }

  void setSpecialty(String value) {
    _specialty = value;
    notifyListeners();
  }

  void setSecurityPin(String value) {
    _securityPin = value;
    _pinError = null;
    notifyListeners();
  }


  void setConnectionCode(String value) {
    _connectionCode = value;
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

  void resetToFirstStep() {
    _currentStep = 0;
    _selectedRole = null;
    _caregiverType = null;
    _connectionChoice = null;
    _clearErrors();
    notifyListeners();
  }

  void switchToLogin() {
    _isLoginMode = true;
    _currentStep = 2; // Login always has email/pass at step 2
    _errorMessage = null;
    notifyListeners();
  }

  void prepareForLogin() {
    _isLoginMode = true;
    _currentStep = 2;
    _selectedRole = 'caregiver'; // Default to caregiver for standard login
    _errorMessage = null;
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

  String? _pinError;
  String? get pinError => _pinError;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _clearErrors() {
    _nameError = null;
    _emailError = null;
    _passwordError = null;
    _confirmPasswordError = null;
    _patientNameError = null;
    _registryError = null;
    _pinError = null;
    _errorMessage = null;
  }

  // Navigation
  Future<void> nextStep() async {
    if (await validateCurrentStep()) {
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

  Future<bool> validateCurrentStep() async {
    _clearErrors();

    if (_currentStep == 0) {
      return _selectedRole != null;
    }

    if (_selectedRole == 'patient') return true;

    // Step 1: Caregiver Type (Familiar/Médico)
    if (_selectedRole == 'caregiver' && _currentStep == 1) {
      return _caregiverType != null;
    }

    // Step 2: Basic Info (Name, Email, Pass, ConfirmPass)
    if (_selectedRole == 'caregiver' && _currentStep == 2) {
      bool isValid = true;
      
      if (_name.trim().isEmpty) {
        _nameError = 'Por favor, informe seu nome completo.';
        isValid = false;
      } else if (_name.trim().split(' ').length < 2) {
        _nameError = 'Informe seu nome e sobrenome.';
        isValid = false;
      }
      
      final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (_email.trim().isEmpty) {
        _emailError = 'Por favor, informe seu e-mail.';
        isValid = false;
      } else if (!emailRegex.hasMatch(_email.trim())) {
        _emailError = 'Por favor, informe um e-mail válido.';
        isValid = false;
      } else {
        // Check if email exists during registration
        _isLoading = true;
        notifyListeners();
        try {
          final isRegistered = await _authRepository.isEmailRegistered(_email);
          if (isRegistered) {
            _emailError = 'Este e-mail já está em uso. Tente outro ou faça login.';
            isValid = false;
          }
        } finally {
          _isLoading = false;
          notifyListeners();
        }
      }

      if (_password.isEmpty) {
        _passwordError = 'Por favor, crie uma senha.';
        isValid = false;
      } else if (_password.length < 6) {
        _passwordError = 'A senha deve ter pelo menos 6 caracteres.';
        isValid = false;
      }
      
      if (_confirmPassword.isEmpty) {
        _confirmPasswordError = 'Confirme sua senha.';
        isValid = false;
      } else if (_password != _confirmPassword) {
        _confirmPasswordError = 'As senhas não coincidem.';
        isValid = false;
      }

      notifyListeners();
      return isValid;
    }

    // Step 3: Professional info
    if (_selectedRole == 'caregiver' &&
        _caregiverType == 'professional' &&
        _currentStep == 3) {
      bool isValid = true;
      if (_professionalRegistry.trim().isEmpty) {
        _registryError = 'Informe seu CRM ou registro profissional.';
        isValid = false;
      }
      notifyListeners();
      return isValid;
    }

    // PIN Step validation
    if (_selectedRole == 'caregiver') {
      bool isPinStep = (_caregiverType == 'professional' && _currentStep == 4) || 
                       (_caregiverType == 'relative' && _currentStep == 3);
      
      if (isPinStep) {
        if (_securityPin.isEmpty) {
          _pinError = 'Por favor, crie um PIN.';
          notifyListeners();
          return false;
        }
        if (_securityPin.length != 4) {
          _pinError = 'O PIN deve ter exatamente 4 dígitos.';
          notifyListeners();
          return false;
        }
        return true;
      }
    }

    return true;
  }

  bool get canSubmit {
    if (_selectedRole == 'patient') return true;
    if (isLoginMode) {
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
      filled = filled && _securityPin.length == 4;
      return filled;
    }
  }

  Future<bool> login() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.signInWithEmailPassword(
        email: _email.trim(),
        password: _password,
      );
      return true;
    } catch (e) {
      _errorMessage = _getFriendlyError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
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
          final displayName = 'Paciente #${Random().nextInt(10000).toString().padLeft(4, '0')}';
          await _authRepository.signInAnonymously(
            role: 'patient',
            fullName: displayName,
          );
        }
      } else {
        final metadata = {
          'full_name': _name.trim(),
          'role': 'caregiver',
          'caregiver_type': _caregiverType,
          'professional_registry': _professionalRegistry,
          'specialty': _specialty,
          'patient_name': _patientName.trim(),
          'patient_stage': _patientStage,
          'patient_birthdate': _formatDateForSupabase(_patientBirthdate.trim()),
          'relationship': null,
          'security_pin': _securityPin,
        };

        try {
          await _authRepository.signUpWithEmailPassword(
            email: _email.trim(),
            password: _password,
            metadata: metadata,
          );
        } catch (e) {
          final errorStr = e.toString().toLowerCase();
          if (errorStr.contains('already registered') || errorStr.contains('user_already_exists')) {
            throw Exception('Este e-mail já está cadastrado. Faça login ou use outro e-mail.');
          } else {
            rethrow;
          }
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
    if (msg.contains('invalid_credentials') || msg.contains('invalid_login_credentials')) {
      return 'Email ou senha incorretos.';
    }
    if (msg.contains('Este e-mail já está em uso')) {
      return msg.replaceAll('Exception: ', '').replaceAll('Erro: ', '');
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

  String? _formatDateForSupabase(String date) {
    if (date.isEmpty) return null;
    final parts = date.split('/');
    if (parts.length == 3) {
      try {
        final d = parts[0].padLeft(2, '0');
        final m = parts[1].padLeft(2, '0');
        final y = parts[2];
        return '$y-$m-$d';
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  User? get currentUser => _authRepository.currentUser;
}
