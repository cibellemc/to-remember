import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../view_models/caregiver_viewmodel.dart';
import '../../../data/repositories/auth_repository.dart';
import 'widgets/performance_chart.dart';

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Codes are no longer managed here
  }

  String _formatStage(dynamic stage) {
    if (stage == null) return 'Não informado';
    final s = stage.toString().toLowerCase();
    switch (s) {
      case 'inicial':
        return 'Inicial';
      case 'moderado':
        return 'Moderado (Intermediário)';
      case 'avancado':
        return 'Avançado';
      default:
        return s.isNotEmpty
            ? s[0].toUpperCase() + s.substring(1)
            : 'Não informado';
    }
  }

  void _showDisconnectConfirm(
    BuildContext context,
    Map<String, dynamic> patient,
    CaregiverViewModel vm,
  ) {
    // Check if this is the last active caregiver
    final activeCount = vm.patientCaregivers
        .where((c) => (c['status'] ?? 'active') == 'active')
        .length;

    if (activeCount <= 1) {
      _showCannotDisconnectDialog(context, patient['name']);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: vm,
        child: AlertDialog(
          title: const Text('Desconectar Paciente'),
          content: Text(
            'Tem certeza que deseja remover o vínculo com ${patient['name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            Consumer<CaregiverViewModel>(
              builder: (context, vm, child) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (vm.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        vm.errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  TextButton(
                    onPressed: vm.isLoading
                        ? null
                        : () async {
                            await vm.disconnectFromPatient(
                              patient['id'].toString(),
                            );
                            if (vm.errorMessage == null && context.mounted) {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Go back to dashboard
                            }
                          },
                    child: vm.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.orange,
                            ),
                          )
                        : const Text(
                            'Desconectar',
                            style: TextStyle(color: Colors.red),
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

  void _showEditDialog(
    BuildContext context,
    Map<String, dynamic> patient,
    CaregiverViewModel vm,
  ) {
    final nameController = TextEditingController(text: patient['name']);
    final birthdateController = TextEditingController(
      text: vm.authRepository.formatDateBR(patient['birth_date']),
    );
    String? selectedStage = patient['stage'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nome', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Nome do paciente',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data de Nascimento',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: birthdateController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'DD/MM/YYYY',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [DateInputFormatter()],
              ),
              const SizedBox(height: 16),
              const Text(
                'Estágio do Alzheimer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedStage,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'inicial', child: Text('Inicial')),
                  DropdownMenuItem(value: 'moderado', child: Text('Moderado')),
                  DropdownMenuItem(value: 'avancado', child: Text('Avançado')),
                ],
                onChanged: (val) => selectedStage = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await vm.updatePatient(
                patientId: patient['id'].toString(),
                name: nameController.text,
                birthdate: birthdateController.text,
                stage: selectedStage,
                isProfileComplete: true,
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaregiverViewModel>();
    final patient = vm.selectedPatient;

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes')),
        body: const Center(child: Text('Nenhum paciente selecionado')),
      );
    }

    final birthDateStr = patient['birth_date'];
    final formattedDate = birthDateStr != null
        ? vm.authRepository.formatDateBR(birthDateStr)
        : null;
    final age = birthDateStr != null ? _calculateAge(birthDateStr) : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Detalhes do paciente'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final patientId = patient['id'].toString();
          await vm.fetchPatientGameData(patientId);
          await vm.fetchPatientCaregivers(patientId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (patient['status'] == 'inactive')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  color: Colors.amber.shade100,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.amber,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Este vínculo está inativo. O monitoramento foi pausado.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF009688), Color(0xFF00796B)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      patient['name'] ?? 'Paciente',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(
                        children: [
                          if (age != null) ...[
                            TextSpan(
                              text: '$age anos',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextSpan(
                              text: ' | Nascido em ${formattedDate ?? ''}',
                            ),
                          ] else
                            TextSpan(
                              text:
                                  'Nascido em ${formattedDate ?? 'Não informado'}',
                            ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Estágio '),
                          TextSpan(
                            text: _formatStage(patient['stage']),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' do Alzheimer'),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                    if (patient['created_by'] ==
                        vm.authRepository.currentUser?.id) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Criado por você',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Ações',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.bar_chart_rounded,
                      label: 'Ver Desempenho',
                      subtitle:
                          'Histórico de jogos, métricas e gráficos de evolução',
                      color: Colors.indigo.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PatientPerformancePage(
                              patient: patient,
                              viewModel: vm,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.edit_note_rounded,
                      label: 'Editar Paciente',
                      subtitle: 'Alterar nome, data de nascimento ou estágio',
                      color: const Color(0xFF009688),
                      onTap: () => _showEditDialog(context, patient, vm),
                    ),
                    _buildActionButton(
                      icon: Icons.visibility_rounded,
                      label: 'Visão do Paciente',
                      subtitle: 'Ver interface e jogar como este paciente',
                      color: Colors.blue.shade700,
                      onTap: () {
                        vm.authRepository.setRoleOverride(
                          'patient',
                          patientId: patient['id'].toString(),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: patient['status'] == 'inactive'
                          ? Icons.restore_rounded
                          : Icons.link_off_rounded,
                      label: patient['status'] == 'inactive'
                          ? 'Reativar Paciente'
                          : 'Desconectar Paciente',
                      subtitle: patient['status'] == 'inactive'
                          ? 'Restabelecer o vínculo com este paciente'
                          : 'Remover o vínculo com este paciente',
                      color: patient['status'] == 'inactive'
                          ? const Color(0xFF009688)
                          : Colors.red.shade700,
                      onTap: () {
                        if (patient['status'] == 'inactive') {
                          _showReactivationDialog(context, vm, patient);
                        } else {
                          _showDisconnectConfirm(context, patient, vm);
                        }
                      },
                    ),
                    const SizedBox(height: 32),

                    if (vm.authRepository.currentRole != 'professional') ...[
                      const Text(
                        'Equipe de Cuidado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (vm.patientCaregivers.isEmpty)
                        const Text('Carregando cuidadores...')
                      else
                        ...vm.patientCaregivers.map(
                          (cg) => _buildCaregiverTile(cg),
                        ),
                      const SizedBox(height: 32),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverTile(Map<String, dynamic> cg) {
    final vm = context.read<CaregiverViewModel>();
    final isMe = cg['id'] == vm.authRepository.currentUser?.id;
    final name = cg['full_name'] ?? 'Membro';
    final roleText = cg['role'] == 'professional' ? 'Profissional' : 'Familiar';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'C';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe
              ? const Color(0xFF009688).withValues(alpha: 0.3)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF1F5F9),
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF009688),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name + (isMe ? ' (Você)' : ''),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  roleText,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          _buildCaregiverStatusBadge(cg['status'] ?? 'active'),
        ],
      ),
    );
  }

  Widget _buildCaregiverStatusBadge(String status) {
    final isActive = status == 'active';
    final greenColor = const Color(0xFF2E7D32);
    final greenBg = const Color(0xFFE8F5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? greenBg : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.check_circle_rounded
                : Icons.pause_circle_filled_rounded,
            size: 14,
            color: isActive ? greenColor : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Ativo' : 'Pausado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isActive ? greenColor : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: color.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _calculateAge(String? birthDateStr) {
    if (birthDateStr == null) return null;
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  void _showCannotDisconnectDialog(BuildContext context, String patientName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Não é possível sair'),
        content: Text(
          'Você é o único cuidador ativo para $patientName. Para se desconectar, você deve primeiro vincular outro cuidador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showReactivationDialog(
    BuildContext context,
    CaregiverViewModel vm,
    Map<String, dynamic> patient,
  ) {
    final codeController = TextEditingController();
    vm.clearError();

    showDialog(
      context: context,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: vm,
          child: Consumer<CaregiverViewModel>(
            builder: (context, vm, child) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text('Reativar ${patient['name']}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (vm.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vm.errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    const Text(
                      'Insira o código de vínculo para reativar o monitoramento.',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        counterText: "",
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: vm.isLoading
                        ? null
                        : () async {
                            await vm.reactivatePatient(
                              patientId: patient['id'].toString(),
                              code: codeController.text.trim().toUpperCase(),
                            );
                            if (vm.errorMessage == null && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reativado com sucesso!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    child: vm.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('REATIVAR'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) return newValue;
    final text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) return oldValue;
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) buffer.write('/');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PatientPerformancePage extends StatefulWidget {
  final Map<String, dynamic> patient;
  final CaregiverViewModel viewModel;

  const PatientPerformancePage({
    super.key,
    required this.patient,
    required this.viewModel,
  });

  @override
  State<PatientPerformancePage> createState() => _PatientPerformancePageState();
}

class _PatientPerformancePageState extends State<PatientPerformancePage> {
  String _selectedGameType = 'memory';

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final vm = widget.viewModel;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Desempenho de ${patient['name'] ?? 'Paciente'}'),
        backgroundColor: const Color(0xFF009688),
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final patientId = patient['id'].toString();
          await vm.fetchPatientGameData(patientId);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 24),
          child: _buildDesempenhoTab(vm),
        ),
      ),
    );
  }

  Widget _buildDesempenhoTab(CaregiverViewModel vm) {
    if (vm.isLoadingGameData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: CircularProgressIndicator(color: Color(0xFF009688)),
        ),
      );
    }

    final allSessions = vm.patientGameSessions;
    final sessions = allSessions
        .where((s) => s['game_type'] == _selectedGameType)
        .toList();
    final totalSessions = sessions.length;

    // Calculate accuracy (precision)
    double avgAccuracy = 0.0;
    int totalHits = 0;
    int totalMistakes = 0;
    for (var s in sessions) {
      totalHits += (s['hits'] as int? ?? 0);
      totalMistakes += (s['mistakes'] as int? ?? 0);
    }
    if (totalHits + totalMistakes > 0) {
      avgAccuracy = totalHits / (totalHits + totalMistakes);
    }

    // Calculate average response time
    double avgResponseTimeSec = 0.0;
    int validTimeSessions = 0;
    double sumResponseTimeSec = 0.0;
    for (var s in sessions) {
      final t = s['avg_response_time_ms'] as num?;
      if (t != null && t > 0) {
        sumResponseTimeSec += t / 1000.0;
        validTimeSessions++;
      }
    }
    if (validTimeSessions > 0) {
      avgResponseTimeSec = sumResponseTimeSec / validTimeSessions;
    }

    // Current level for selected game
    int currentLevel = 1;
    String currentLevelTitle = '';
    IconData currentLevelIcon = Icons.gamepad;

    if (_selectedGameType == 'memory') {
      currentLevelTitle = 'Jogo da Memória';
      currentLevelIcon = Icons.psychology;
    } else if (_selectedGameType == 'ocorrencias') {
      currentLevelTitle = 'Encontre as Ocorrências';
      currentLevelIcon = Icons.grid_on;
    }

    for (var prog in vm.patientGameProgressList) {
      if (prog['game_type']?.toString() == _selectedGameType) {
        currentLevel = prog['current_level'] as int? ?? 1;
        break;
      }
    }

    // For chart, show chronologically (oldest to newest), limit to last 10
    final chartSessions = sessions.reversed.take(10).toList();

    final List<double> chartData = [];
    final List<String> chartLabels = [];
    for (int i = 0; i < chartSessions.length; i++) {
      final s = chartSessions[i];
      final h = s['hits'] as int? ?? 0;
      final m = s['mistakes'] as int? ?? 0;
      final tot = h + m;
      final acc = tot > 0 ? h / tot : 0.0;
      chartData.add(acc);

      try {
        final date = DateTime.parse(s['played_at'].toString()).toLocal();
        chartLabels.add("${date.day}/${date.month}");
      } catch (_) {
        chartLabels.add("#${i + 1}");
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game selection pills
          const Text(
            'Selecione o Jogo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildGamePill('memory', 'Memória'),
                const SizedBox(width: 12),
                _buildGamePill('ocorrencias', 'Ocorrências'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Section Title
          const Text(
            'Métricas Gerais',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),

          // Metrics grid
          Column(
            children: [
              _buildStatCard(
                'Partidas Jogadas',
                '$totalSessions',
                Icons.sports_esports,
                const Color(0xFF009688),
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Precisão Média',
                totalSessions > 0
                    ? '${(avgAccuracy * 100).toStringAsFixed(0)}%'
                    : '-',
                Icons.check_circle_outline,
                Colors.green,
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Tempo de Resposta Médio',
                avgResponseTimeSec > 0
                    ? '${avgResponseTimeSec.toStringAsFixed(1)}s'
                    : '-',
                Icons.timer_outlined,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Current levels card
          const Text(
            'Progresso de Nível',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildLevelRow(
                  currentLevelTitle,
                  currentLevel,
                  currentLevelIcon,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Chart Section
          const Text(
            'Gráfico de Evolução',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          PerformanceChart(
            dataPoints: chartData,
            xLabels: chartLabels,
            minY: 0.0,
            maxY: 1.0,
            yLabelFormatter: (val) => '${(val * 100).toInt()}%',
            color: const Color(0xFF009688),
            emptyMessage: 'Sem partidas registradas ainda.',
          ),
          const SizedBox(height: 28),

          // Sessions History list
          const Text(
            'Histórico Recente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Center(
                child: Text(
                  'Nenhuma partida registrada para este jogo.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              ),
            )
          else
            ...sessions
                .take(15)
                .map(
                  (s) =>
                      _SessionTile(session: s, formatDateTime: _formatDateTime),
                ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildLevelRow(String title, int level, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF009688), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            Text(
              'Nível $level de 5',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: level / 5.0,
            minHeight: 10,
            backgroundColor: Colors.grey.shade100,
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF009688)),
          ),
        ),
      ],
    );
  }

  Widget _buildGamePill(String type, String label) {
    final isSelected = _selectedGameType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedGameType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009688) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF009688) : Colors.grey.shade300,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF009688).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();

      final isToday =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final isYesterday =
          dt.year == now.year && dt.month == now.month && dt.day == now.day - 1;

      final hourStr = dt.hour.toString().padLeft(2, '0');
      final minStr = dt.minute.toString().padLeft(2, '0');
      final timeStr = "$hourStr:$minStr";

      if (isToday) {
        return "Hoje, $timeStr";
      } else if (isYesterday) {
        return "Ontem, $timeStr";
      } else {
        final months = [
          'Jan',
          'Fev',
          'Mar',
          'Abr',
          'Mai',
          'Jun',
          'Jul',
          'Ago',
          'Set',
          'Out',
          'Nov',
          'Dez',
        ];
        return "${dt.day} de ${months[dt.month - 1]}, $timeStr";
      }
    } catch (_) {
      return dateStr;
    }
  }
}

// ───────────────────────────────────────────────────────────────────────────────
// SESSION TILE WITH EXPANDABLE ROUND DETAILS
// ───────────────────────────────────────────────────────────────────────────────

class _SessionTile extends StatefulWidget {
  final Map<String, dynamic> session;
  final String Function(String?) formatDateTime;

  const _SessionTile({required this.session, required this.formatDateTime});

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final gameType = session['game_type']?.toString() ?? '';
    final initialLevel = session['initial_level'] as int? ?? 1;
    final finalLevel = session['final_level'] as int? ?? 1;
    final hits = session['hits'] as int? ?? 0;
    final mistakes = session['mistakes'] as int? ?? 0;
    final total = hits + mistakes;
    final accuracy = total > 0 ? (hits / total) : 0.0;
    final avgTimeMs = session['avg_response_time_ms'] as int? ?? 0;
    final playedAt = session['played_at']?.toString();
    final decision = session['fuzzy_decision']?.toString() ?? 'Manter';

    // round_details from performance_data
    final perfData = session['performance_data'];
    final List<dynamic> roundDetails = (perfData is Map)
        ? (perfData['round_details'] as List? ?? [])
        : [];

    String gameName = 'Jogo';
    IconData gameIcon = Icons.sports_esports;
    if (gameType == 'memoria') {
      gameName = 'Jogo da Memória';
      gameIcon = Icons.psychology;
    } else if (gameType == 'ocorrencias') {
      gameName = 'Encontre as Ocorrências';
      gameIcon = Icons.grid_on;
    } else if (gameType == 'matching') {
      gameName = 'Correspondência';
      gameIcon = Icons.extension;
    }

    Color decisionColor = Colors.grey;
    IconData decisionIcon = Icons.trending_flat;
    if (decision == 'Aumentar') {
      decisionColor = Colors.green;
      decisionIcon = Icons.trending_up;
    } else if (decision == 'Diminuir') {
      decisionColor = Colors.orange;
      decisionIcon = Icons.trending_down;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF009688).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        gameIcon,
                        color: const Color(0xFF009688),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gameName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.formatDateTime(playedAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: decisionColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(decisionIcon, color: decisionColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            decision,
                            style: TextStyle(
                              color: decisionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatDetail('Nível', '$initialLevel ➔ $finalLevel'),
                    _buildStatDetail(
                      'Acertos',
                      '$hits/$total (${(accuracy * 100).toStringAsFixed(0)}%)',
                    ),
                    _buildStatDetail(
                      'Tempo Médio',
                      avgTimeMs > 0
                          ? '${(avgTimeMs / 1000).toStringAsFixed(1)}s'
                          : '-',
                    ),
                  ],
                ),
                // "Ver rodadas" button — only if round_details exists
                if (roundDetails.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: Row(
                      children: [
                        Text(
                          _expanded ? 'Ocultar rodadas' : 'Ver rodadas',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF009688),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Color(0xFF009688),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Expandable round details
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade100),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalhes por rodada',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...roundDetails.map((rd) {
                          final r = rd as Map<String, dynamic>;
                          final roundNum = r['round'] as int? ?? 0;
                          final rHits = r['hits'] as int? ?? 0;
                          final rMistakes = r['mistakes'] as int? ?? 0;
                          final rTimeMs = r['time_ms'] as int? ?? 0;
                          final perfect = rMistakes == 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: perfect
                                    ? Colors.green.withValues(alpha: 0.2)
                                    : Colors.orange.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: perfect
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : Colors.orange.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      perfect
                                          ? Icons.check_circle_rounded
                                          : Icons.warning_amber_rounded,
                                      size: 16,
                                      color: perfect
                                          ? Colors.green.shade600
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Rodada $roundNum',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                                _buildRoundBadge(
                                  '✔ $rHits acerto${rHits != 1 ? 's' : ''}',
                                  Colors.green.shade700,
                                  Colors.green.shade50,
                                ),
                                const SizedBox(width: 6),
                                _buildRoundBadge(
                                  '✘ $rMistakes erro${rMistakes != 1 ? 's' : ''}',
                                  rMistakes == 0
                                      ? Colors.grey.shade400
                                      : Colors.orange.shade700,
                                  rMistakes == 0
                                      ? Colors.grey.shade50
                                      : Colors.orange.shade50,
                                ),
                                const SizedBox(width: 6),
                                _buildRoundBadge(
                                  '⏱ ${(rTimeMs / 1000).toStringAsFixed(1)}s',
                                  Colors.blueGrey.shade600,
                                  Colors.blueGrey.shade50,
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
