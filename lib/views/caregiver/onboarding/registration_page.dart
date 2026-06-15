import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../view_models/login_viewmodel.dart';
import '../../jogo/jogo_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../home/caregiver_home_page.dart';
import '../../login/login_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _registryController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _patientNameController = TextEditingController();
  final _patientBirthdateController = TextEditingController();
  final _connectionCodeController = TextEditingController();
  final _pinController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  int _lastStep = 0;
  bool _isMovingForward = true;

  @override
  void initState() {
    super.initState();
    // Ensure we start in registration mode but don't reset step to 0
    // so we preserve progress if coming back from login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = Provider.of<LoginViewModel>(context, listen: false);
      vm.setLoginMode(false);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _registryController.dispose();
    _specialtyController.dispose();
    _patientNameController.dispose();
    _patientBirthdateController.dispose();
    _connectionCodeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<LoginViewModel>(context);
    final primaryColor = const Color(0xFF009688);

    if (vm.currentStep != _lastStep) {
      _isMovingForward = vm.currentStep > _lastStep;
      _lastStep = vm.currentStep;
    }

    return PopScope(
      canPop: vm.currentStep == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (vm.currentStep > 0) {
          vm.previousStep();
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: vm.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black54),
                onPressed: () {
                  vm.previousStep();
                },
              )
            : null,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'images/logo.svg',
              colorFilter: ColorFilter.mode(primaryColor, BlendMode.srcIn),
              width: 40,
              height: 40,
            ),
            const SizedBox(width: 8),
            const Text(
              'To Remember',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (vm.currentStep == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.black54, size: 28),
                onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sobre o App'),
                    content: const Text(
                      'O To Remember é uma ferramenta para auxiliar no tratamento e acompanhamento de pacientes com Alzheimer.\n\n'
                      '• JOGAR: Para o paciente realizar os exercícios de estímulo cognitivo.\n\n'
                      '• ACOMPANHAR: Para cuidadores, familiares ou profissionais de saúde monitorarem o progresso do paciente.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Entendi'),
                      ),
                    ],
                  ),
                );
              },
            ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey.shade100, thickness: 1),
                    const SizedBox(height: 20),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        final isIncoming =
                            (child.key as ValueKey<int>).value ==
                            vm.currentStep;

                        Offset begin;
                        if (_isMovingForward) {
                          begin = isIncoming
                              ? const Offset(1.0, 0.0)
                              : const Offset(-1.0, 0.0);
                        } else {
                          begin = isIncoming
                              ? const Offset(-1.0, 0.0)
                              : const Offset(1.0, 0.0);
                        }

                        return SlideTransition(
                          position:
                              Tween<Offset>(
                                begin: begin,
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        key: ValueKey<int>(vm.currentStep),
                        child: _buildStepContent(context, vm, primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomAction(vm, primaryColor),
          ],
        ),
      ),
    ),
    ),
    ),
  );
}

  Widget _buildStepContent(
    BuildContext context,
    LoginViewModel vm,
    Color primaryColor,
  ) {
    switch (vm.currentStep) {
      case 0:
        return _buildRoleSelection(context, vm, primaryColor);
      case 1:
        return _buildCaregiverTypeSelection(vm, primaryColor);
      case 2:
        return _buildBasicInfo(vm, primaryColor);
      case 3:
        if (vm.caregiverType == 'professional') {
          return _buildProfessionalInfo(vm, primaryColor);
        }
        return _buildPinStep(vm, primaryColor);
      case 4:
        return _buildPinStep(vm, primaryColor);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPinStep(LoginViewModel vm, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PIN de Segurança',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const Text(
          'Crie um PIN de 4 dígitos. Ele será necessário para sair da visão do paciente e acessar seu painel.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _SegmentedProgress(
          stepNames: _getStepNames(vm),
          currentStepIndex: vm.currentStep - 1,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 32),
        Center(
          child: SizedBox(
            width: 200,
            child: TextField(
              key: const Key('input_pin_registration'),
              controller: _pinController,
              onChanged: vm.setSecurityPin,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 16),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••',
                hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 16),
                errorText: vm.pinError,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 20),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelection(BuildContext context, LoginViewModel vm, Color primaryColor) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildBigActionCard(
              title: 'JOGAR',
              icon: Icons.extension,
              color: const Color(0xFF1565C0), // Blue 800 (Alto contraste AAA)
              isLoading: vm.isLoading,
              onTap: vm.isLoading
                  ? null
                  : () async {
            vm.setRole('patient');
            final success = await vm.finishRegistration();
            if (success && mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PatientHomePage()),
              );
            } else if (!success && mounted && vm.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(vm.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        const SizedBox(height: 24),
        _buildBigActionCard(
          title: 'ACOMPANHAR\nPACIENTE',
          icon: Icons.volunteer_activism, // Ícone sugerindo cuidado, apoio e conexão
          color: const Color(0xFF00695C), // Teal 800 (Alto contraste AAA)
          onTap: vm.isLoading
              ? null
              : () {
            vm.setRole('caregiver');
            Future.delayed(
              const Duration(milliseconds: 100),
              () {
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            );
          },
        ),
        const SizedBox(height: 48),
        Text(
          'To Remember © 2026',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ],
    ),
    ),
    );
  }

  Widget _buildBigActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Material(
      color: onTap == null ? color.withValues(alpha: 0.6) : color,
      borderRadius: BorderRadius.circular(24),
      elevation: 4, // Adiciona um pequeno sombreamento para destacar o clique (acessibilidade visual)
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 6,
                  ),
                )
              else
                Icon(icon, size: 88, color: Colors.white),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverTypeSelection(LoginViewModel vm, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qual seu perfil?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _SegmentedProgress(
          stepNames: _getStepNames(vm),
          currentStepIndex: vm.currentStep - 1,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 24),
        _OptionCard(
          title: 'Familiar / Amigo',
          subtitle: 'Acompanhe o dia a dia de quem você cuida',
          icon: Icons.people,
          isSelected: vm.caregiverType == 'relative',
          onTap: () {
            vm.setCaregiverType('relative');
            Future.delayed(
              const Duration(milliseconds: 400),
              () => vm.nextStep(),
            );
          },
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 16),
        _OptionCard(
          title: 'Médico / Enfermeiro',
          subtitle: 'Profissional de saúde com registro',
          icon: Icons.medical_services,
          isSelected: vm.caregiverType == 'professional',
          onTap: () {
            vm.setCaregiverType('professional');
            Future.delayed(
              const Duration(milliseconds: 300),
              () => vm.nextStep(),
            );
          },
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildBasicInfo(LoginViewModel vm, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações básicas',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _SegmentedProgress(
          stepNames: _getStepNames(vm),
          currentStepIndex: vm.currentStep - 1,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 24),
        _buildField(
          label: 'Nome completo',
          hint: 'Ex: Maria da Silva',
          controller: _nameController,
          onChanged: vm.setName,
          error: vm.nameError,
        ),
        const SizedBox(height: 20),
        _buildField(
          label: 'E-mail',
          hint: 'Ex: maria@email.com',
          controller: _emailController,
          onChanged: vm.setEmail,
          error: vm.emailError,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _buildField(
          label: 'Senha',
          hint: 'Mínimo 6 caracteres',
          controller: _passwordController,
          onChanged: vm.setPassword,
          error: vm.passwordError,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
        const SizedBox(height: 20),
        _buildField(
          label: 'Confirmar senha',
          hint: 'Repita sua senha',
          controller: _confirmPasswordController,
          onChanged: vm.setConfirmPassword,
          error: vm.confirmPasswordError,
          obscureText: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 20,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalInfo(LoginViewModel vm, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dados profissionais',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _SegmentedProgress(
          stepNames: _getStepNames(vm),
          currentStepIndex: vm.currentStep - 1,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 24),
        _buildField(
          label: 'CRM / Registro profissional',
          hint: 'Ex: CRM/SP 123456',
          controller: _registryController,
          onChanged: vm.setProfessionalRegistry,
          error: vm.registryError,
        ),
        const SizedBox(height: 20),
        _buildField(
          label: 'Especialidade / Área de atuação',
          hint: 'Ex: Geriatria, Neurologia',
          controller: _specialtyController,
          onChanged: vm.setSpecialty,
        ),
      ],
    );
  }

  List<String> _getStepNames(LoginViewModel vm) {
    final names = <String>['Tipo'];
    names.add('Dados');
    if (vm.caregiverType == 'professional') names.add('Profis.');
    names.add('PIN');
    return names;
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? error,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.teal.shade300, width: 2),
            ),
            errorText: error,
            suffixIcon: suffixIcon,
            errorStyle: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(LoginViewModel vm, Color primaryColor) {
    bool isLast;
    if (vm.isLoginMode) {
      isLast = vm.currentStep == 2;
    } else {
      isLast = (vm.caregiverType == 'relative' && vm.currentStep == 3) ||
               (vm.caregiverType == 'professional' && vm.currentStep == 4);
    }

    if (vm.currentStep == 0 || vm.currentStep == 1) {
      return const SizedBox.shrink();
    }

    bool isValid = true; // Always enable to allow validation feedback on click

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vm.errorMessage != null) ...[
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            if (vm.errorMessage!.contains('já está em uso') || vm.errorMessage!.contains('já está cadastrado')) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => vm.switchToLogin(),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text(
                  'Fazer Login agora',
                  style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
                style: TextButton.styleFrom(foregroundColor: primaryColor),
              ),
            ],
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (!isValid || vm.isLoading)
                  ? null
                  : () async {
                      if (!await vm.validateCurrentStep()) return;
                      if (isLast) {
                        final success = vm.isLoginMode 
                            ? await vm.login() 
                            : await vm.finishRegistration();
                            
                        if (success && mounted) {
                          if (vm.selectedRole == 'patient') {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const PatientHomePage()),
                            );
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const CaregiverHomePage()),
                            );
                          }
                        }
                      } else {
                        vm.nextStep();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: vm.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                        isLast ? (vm.isLoginMode ? 'Entrar' : 'Finalizar') : 'Continuar',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minHeight: 140),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade100,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.black45,
                size: 40,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedProgress extends StatelessWidget {
  final List<String> stepNames;
  final int currentStepIndex;
  final Color primaryColor;

  const _SegmentedProgress({
    required this.stepNames,
    required this.currentStepIndex,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(stepNames.length, (index) {
            bool active = index <= currentStepIndex;
            return Expanded(
              child: Container(
                height: 6,
                margin: EdgeInsets.only(
                  right: index == stepNames.length - 1 ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  color: active ? primaryColor : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
