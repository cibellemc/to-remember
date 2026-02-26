import 'package:flutter/material.dart';
import '../home/caregiver_home_page.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int? _selectedUserType = 1;

  final int _totalPages = 3;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const CaregiverHomePage()),
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Cadastro de Cuidador'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousPage,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Progress Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentPage == index ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? theme.primaryColor
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildProfileStep(theme),
                  _buildDataStep(theme),
                  _buildLinkStep(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(
                    _currentPage == _totalPages - 1 ? 'Concluir' : 'Continuar',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.badge, size: 80, color: Colors.teal),
          const SizedBox(height: 24),
          Text(
            'Perfil Profissional',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Quem é você na relação de cuidado?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          _buildSelectionCard('Familiar', Icons.family_restroom, 1),
          const SizedBox(height: 16),
          _buildSelectionCard(
            'Médico / Profissional',
            Icons.medical_services,
            2,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionCard(String title, IconData icon, int value) {
    final isSelected = _selectedUserType == value;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _selectedUserType = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.primaryColor : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.primaryColor : Colors.grey.shade700,
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle, color: theme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: SingleChildScrollView(
        // Changed to Scrollable for smaller screens
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person_outline, size: 80, color: Colors.teal),
            const SizedBox(height: 24),
            Text(
              'Seus Dados',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 40),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Nome Completo',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2, size: 80, color: Colors.teal),
          const SizedBox(height: 24),
          Text(
            'Vincular Paciente',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Escaneie o QR Code do paciente para conectar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 40),
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: theme.primaryColor, width: 2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                Icons.camera_alt,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.keyboard),
            label: const Text('Digitar código manualmente'),
          ),
        ],
      ),
    );
  }
}
