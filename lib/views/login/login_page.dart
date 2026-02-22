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
  final _patientNameController = TextEditingController();
  final _registryController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _patientNameController.dispose();
    _registryController.dispose();
    super.dispose();
  }

  Future<void> _handleFinish(BuildContext context, LoginViewModel vm) async {
    final success = await vm.finishRegistration();
    if (!context.mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => vm.selectedRole == 'patient'
              ? const PatientHomePage()
              : const CaregiverHomePage(),
        ),
      );
    } else if (vm.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoginViewModel>(
      builder: (context, vm, _) {
        final isLastStep = _isLastStep(vm);
        final totalSteps = _totalSteps(vm);

        return Scaffold(
          appBar: AppBar(
            leading: vm.currentStep > 0
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: vm.previousStep,
                  )
                : null,
            automaticallyImplyLeading: vm.currentStep > 0,
            title: Text(_stepTitle(vm)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Column(
            children: [
              // Progress bar
              if (totalSteps > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: List.generate(totalSteps, (i) {
                      final done = i < vm.currentStep;
                      final current = i == vm.currentStep;
                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: done || current
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              const SizedBox(height: 8),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildStep(context, vm),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: vm.isLoading
                        ? null
                        : () {
                            if (isLastStep) {
                              _handleFinish(context, vm);
                            } else {
                              vm.nextStep();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLastStep || vm.currentStep == 0
                          ? Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.5)
                          : Theme.of(context).primaryColor,
                      // Match the mockup's softer teal color if not last stage or specific logic
                      // But I'll stick to a consistent style for now as requested.
                    ),
                    child: vm.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLastStep
                                    ? 'CONCLUIR'
                                    : (vm.currentStep == 0
                                          ? 'Continuar'
                                          : 'PRÓXIMO'),
                              ),
                              if (vm.currentStep == 0) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 18),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _totalSteps(LoginViewModel vm) {
    if (vm.selectedRole == 'patient') return 2;
    return vm.isLoginMode ? 2 : 3;
  }

  bool _isLastStep(LoginViewModel vm) {
    if (vm.selectedRole == 'patient' && vm.currentStep == 1) return true;
    if (vm.selectedRole == 'caregiver' && vm.isLoginMode && vm.currentStep == 1)
      return true;
    if (vm.selectedRole == 'caregiver' &&
        !vm.isLoginMode &&
        vm.currentStep == 2)
      return true;
    return false;
  }

  String _stepTitle(LoginViewModel vm) {
    switch (vm.currentStep) {
      case 0:
        return 'Identificação';
      case 1:
        if (vm.selectedRole == 'patient') return 'Como te chamamos?';
        return 'Sua Conta';
      case 2:
        return 'Dados do Paciente';
      default:
        return '';
    }
  }

  Widget _buildStep(BuildContext context, LoginViewModel vm) {
    final theme = Theme.of(context);
    // Step 0: Role Selection
    if (vm.currentStep == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Subheader from mockup
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.favorite,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'To Remember',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Como você quer\nusar o app?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha seu perfil para começar.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          _RoleCard(
            title: 'Quero jogar',
            subtitle:
                'Sou paciente ou quero usar os jogos e atividades do app.',
            image: 'images/role-patient.jpg',
            isSelected: vm.selectedRole == 'patient',
            onTap: () => vm.setRole('patient'),
          ),
          const SizedBox(height: 16),
          _RoleCard(
            title: 'Sou cuidador',
            subtitle: 'Cuido de alguém e quero acompanhar o progresso.',
            image: 'images/role-caregiver.jpg',
            isSelected: vm.selectedRole == 'caregiver',
            onTap: () => vm.setRole('caregiver'),
          ),
          const SizedBox(height: 32),
        ],
      );
    }

    // Step 1 - Patient: Name
    if (vm.selectedRole == 'patient' && vm.currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como você prefere ser chamado?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            onChanged: vm.setName,
            decoration: InputDecoration(
              labelText: 'Seu nome (opcional)',
              prefixIcon: const Icon(Icons.edit),
              errorText: vm.nameError,
            ),
          ),
        ],
      );
    }

    // Step 1 - Caregiver: Account
    if (vm.selectedRole == 'caregiver' && vm.currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _AuthModeCard(
                  title: 'PRIMEIRA VEZ',
                  icon: Icons.person_add,
                  isSelected: !vm.isLoginMode,
                  onTap: () {
                    if (vm.isLoginMode) vm.toggleLoginMode();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AuthModeCard(
                  title: 'JÁ TENHO CONTA',
                  icon: Icons.login,
                  isSelected: vm.isLoginMode,
                  onTap: () {
                    if (!vm.isLoginMode) vm.toggleLoginMode();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (!vm.isLoginMode) ...[
            TextField(
              controller: _nameController,
              onChanged: vm.setName,
              decoration: InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: const Icon(Icons.person),
                errorText: vm.nameError,
              ),
            ),
            const SizedBox(height: 20),
          ],
          TextField(
            controller: _emailController,
            onChanged: vm.setEmail,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              errorText: vm.emailError,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            onChanged: vm.setPassword,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock),
              errorText: vm.passwordError,
            ),
          ),
          if (!vm.isLoginMode) ...[
            const SizedBox(height: 20),
            TextField(
              controller: _confirmPasswordController,
              onChanged: vm.setConfirmPassword,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: vm.confirmPasswordError,
              ),
            ),
          ],
        ],
      );
    }

    // Step 2 - Caregiver: Patient info
    if (vm.selectedRole == 'caregiver' && vm.currentStep == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quem é o paciente?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _patientNameController,
            onChanged: vm.setPatientName,
            decoration: InputDecoration(
              labelText: 'Nome do paciente',
              prefixIcon: const Icon(Icons.favorite),
              errorText: vm.patientNameError,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Qual sua relação?',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 16),
          _RoleCard(
            title: 'Parente ou Amigo',
            subtitle: 'Cuidado familiar',
            image: 'images/onboarding_3.png', // Using a family-related image
            isSelected: vm.caregiverType == 'relative',
            onTap: () => vm.setCaregiverType('relative'),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            title: 'Profissional',
            subtitle: 'Médico / Enfermeiro',
            image: 'images/role-caregiver.jpg',
            isSelected: vm.caregiverType == 'professional',
            onTap: () => vm.setCaregiverType('professional'),
          ),
          if (vm.caregiverType == 'professional') ...[
            const SizedBox(height: 24),
            TextField(
              controller: _registryController,
              onChanged: vm.setProfessionalRegistry,
              decoration: InputDecoration(
                labelText: 'Registro (CRM/COREM)',
                prefixIcon: const Icon(Icons.badge),
                errorText: vm.registryError,
              ),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Componentes reutilizáveis ────────────────────────────

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Image.asset(image, height: 120, fit: BoxFit.contain),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        height: 12,
                        width: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthModeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _AuthModeCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
