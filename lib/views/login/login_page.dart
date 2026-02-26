import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/login_viewmodel.dart';
import '../caregiver/home/caregiver_home_page.dart';
import '../jogo/jogo_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _registryController = TextEditingController();
  final _specialtyController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _registryController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<LoginViewModel>(context);
    final primaryColor = const Color(0xFF009688); // Teal color from images

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: vm.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black54),
                onPressed: vm.previousStep,
              )
            : null,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 20),
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
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildStepContent(context, vm, primaryColor),
              ),
            ),
            _buildBottomAction(vm, primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    LoginViewModel vm,
    Color primaryColor,
  ) {
    if (vm.selectedRole == 'patient') {
      return _buildRoleSelection(vm, primaryColor);
    }

    switch (vm.currentStep) {
      case 0:
        return _buildRoleSelection(vm, primaryColor);
      case 1:
        return _buildFirstTimeCheck(vm, primaryColor);
      case 2:
        return vm.isLoginMode
            ? _buildBasicInfo(vm, primaryColor)
            : _buildCaregiverTypeSelection(vm, primaryColor);
      case 3:
        return _buildBasicInfo(vm, primaryColor);
      case 4:
        return _buildProfessionalInfo(vm, primaryColor);
      default:
        return const SizedBox();
    }
  }

  Widget _buildRoleSelection(LoginViewModel vm, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como você quer usar o app?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        // const SizedBox(height: 12),
        // const Text(
        //   'Escolha seu perfil para começar.',
        //   style: TextStyle(fontSize: 18, color: Colors.black54),
        // ),
        const SizedBox(height: 32),
        _OptionCard(
          title: 'Quero jogar',
          subtitle: 'Sou paciente ou quero usar os jogos e atividades do app.',
          icon: Icons.videogame_asset_outlined,
          isSelected: vm.selectedRole == 'patient',
          onTap: () {
            vm.setRole('patient');
            // For patient, role selection is the last step.
            // Do not auto advance. Just show the final button.
          },
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 16),
        _OptionCard(
          title: 'Sou cuidador',
          subtitle: 'Cuido de alguém e quero acompanhar o progresso.',
          icon: Icons.person_search_outlined,
          isSelected: vm.selectedRole == 'caregiver',
          onTap: () {
            vm.setRole('caregiver');
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

  Widget _buildFirstTimeCheck(LoginViewModel vm, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'É sua primeira vez aqui?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        // const SizedBox(height: 12),
        // const Text(
        //   'Assim podemos direcionar você corretamente.',
        //   style: TextStyle(fontSize: 18, color: Colors.black54),
        // ),
        const SizedBox(height: 32),
        _OptionCard(
          title: 'Sim, sou novo',
          subtitle: 'Quero criar minha conta e começar a usar o app.',
          icon: Icons.auto_awesome_outlined,
          isSelected: vm.isLoginModeRaw == false,
          onTap: () {
            vm.setLoginMode(false);
            Future.delayed(
              const Duration(milliseconds: 300),
              () => vm.nextStep(),
            );
          },
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 16),
        _OptionCard(
          title: 'Já tenho conta',
          subtitle: 'Quero entrar com meu e-mail e senha.',
          icon: Icons.login_outlined,
          isSelected: vm.isLoginModeRaw == true,
          onTap: () {
            vm.setLoginMode(true);
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

  Widget _buildCaregiverTypeSelection(LoginViewModel vm, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qual seu perfil?',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        // const SizedBox(height: 12),
        // const Text(
        //   'Assim podemos direcionar você corretamente.',
        //   style: TextStyle(fontSize: 18, color: Colors.black54),
        // ),
        const SizedBox(height: 24),
        _SegmentedProgress(
          stepNames: vm.caregiverType == 'professional'
              ? const [
                  'Perfil do cuidador',
                  'Dados básicos',
                  'Dados profissionais',
                ]
              : const ['Perfil do cuidador', 'Dados básicos'],
          currentStepIndex: 0,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 24),
        _OptionCard(
          title: 'Familiar / Amigo',
          subtitle: 'Acompanhe o dia a dia de quem você cuida',
          icon: Icons.people_outline,
          isSelected: vm.caregiverType == 'relative',
          onTap: () {
            vm.setCaregiverType('relative');
            Future.delayed(
              const Duration(milliseconds: 300),
              () => vm.nextStep(),
            );
          },
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 16),
        _OptionCard(
          title: 'Médico / Enfermeiro',
          subtitle: 'Profissional de saúde com registro',
          icon: Icons.medical_services_outlined,
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
        const SizedBox(height: 24),
        Center(
          child: _LoginLink(vm: vm, primaryColor: primaryColor),
        ),
      ],
    );
  }

  Widget _buildBasicInfo(LoginViewModel vm, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vm.isLoginMode ? 'Acesse sua conta' : 'Informações básicas',
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        // const SizedBox(height: 12),
        // Text(
        //   vm.isLoginMode
        //       ? 'Preencha seus dados para entrar.'
        //       : 'Preencha seus dados para criar sua conta.',
        //   style: const TextStyle(fontSize: 18, color: Colors.black54),
        // ),
        const SizedBox(height: 24),
        if (!vm.isLoginMode) ...[
          _SegmentedProgress(
            stepNames: vm.caregiverType == 'professional'
                ? const [
                    'Perfil do cuidador',
                    'Dados básicos',
                    'Dados profissionais',
                  ]
                : const ['Perfil do cuidador', 'Dados básicos'],
            currentStepIndex: 1,
            primaryColor: primaryColor,
          ),
          const SizedBox(height: 24),
        ],
        if (!vm.isLoginMode) ...[
          _buildField(
            label: 'Nome completo',
            hint: 'Ex: Maria da Silva',
            controller: _nameController,
            onChanged: vm.setName,
            error: vm.nameError,
          ),
          const SizedBox(height: 20),
        ],
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
        if (!vm.isLoginMode) ...[
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
        const SizedBox(height: 24),
        Center(
          child: _LoginLink(vm: vm, primaryColor: primaryColor),
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
        const SizedBox(height: 12),
        const Text(
          'Precisamos validar seu registro como profissional.',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        _SegmentedProgress(
          stepNames: const [
            'Perfil do cuidador',
            'Dados básicos',
            'Dados profissionais',
          ],
          currentStepIndex: 2,
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
    bool isLast = false;
    bool showButton = false;

    if (vm.selectedRole == 'patient' && vm.currentStep == 0) {
      isLast = true;
      showButton = true;
    } else if (vm.selectedRole == 'caregiver') {
      if (vm.isLoginMode && vm.currentStep == 2) {
        isLast = true;
        showButton = true;
      } else if (!vm.isLoginMode) {
        if (vm.caregiverType == 'relative' && vm.currentStep == 3) {
          isLast = true;
          showButton = true;
        } else if (vm.caregiverType == 'professional') {
          if (vm.currentStep == 4) {
            isLast = true;
            showButton = true;
          } else if (vm.currentStep == 3) {
            isLast = false;
            showButton = true;
          }
        }
      }
    }

    if (!showButton) return const SizedBox.shrink();

    bool isValid = false;
    if (isLast) {
      isValid = vm.canSubmit;
    } else {
      isValid =
          vm.name.trim().isNotEmpty &&
          vm.email.trim().isNotEmpty &&
          vm.password.isNotEmpty &&
          vm.confirmPassword.isNotEmpty;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (vm.errorMessage != null) ...[
            Text(
              vm.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (!isValid || vm.isLoading)
                  ? null
                  : () async {
                      if (!vm.validateCurrentStep()) return;

                      if (isLast) {
                        final success = await vm.finishRegistration();
                        if (success && mounted) {
                          if (vm.selectedRole == 'patient') {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const PatientHomePage(),
                              ),
                            );
                          } else {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const CaregiverHomePage(),
                              ),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? 'Finalizar' : 'Continuar',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // const SizedBox(width: 8),
                        // Icon(
                        //   isLast ? Icons.check : Icons.arrow_forward,
                        //   size: 18,
                        // ),
                      ],
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
                    color: primaryColor.withOpacity(0.1),
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
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isSelected ? primaryColor : Colors.black45,
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

class _LoginLink extends StatelessWidget {
  final LoginViewModel vm;
  final Color primaryColor;

  const _LoginLink({required this.vm, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        vm.toggleLoginMode();
      },
      child: RichText(
        text: TextSpan(
          text: vm.isLoginMode ? 'Ainda não tem conta? ' : 'Já tem uma conta? ',
          style: const TextStyle(color: Colors.black54, fontSize: 18),
          children: [
            TextSpan(
              text: vm.isLoginMode ? 'Criar' : 'Entrar',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
