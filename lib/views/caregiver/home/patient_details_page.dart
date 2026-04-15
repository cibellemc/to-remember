import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../view_models/caregiver_viewmodel.dart';
import '../../jogo/jogo_page.dart';

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
        return s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : 'Não informado';
    }
  }

  void _showDisconnectConfirm(
    BuildContext context,
    Map<String, dynamic> patient,
    CaregiverViewModel vm,
  ) {
    // Check if this is the last active caregiver
    final activeCount = vm.patientCaregivers.where((c) => (c['status'] ?? 'active') == 'active').length;
    
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
                            await vm.disconnectFromPatient(patient['id'].toString());
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
                                strokeWidth: 2, color: Colors.orange))
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
      text: vm.authRepository.formatDateBR(patient['birth_date'])
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
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Nome do paciente'),
              ),
              const SizedBox(height: 16),
              const Text('Data de Nascimento', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: birthdateController,
                decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'DD/MM/YYYY'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  DateInputFormatter(),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Estágio do Alzheimer', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStage,
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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

  Widget _buildSmallInfoCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Este vínculo está inativo. O monitoramento foi pausado.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ],
                ),
              ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 40),
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: Text(
                        (patient['name'] as String?)?[0].toUpperCase() ?? 'P',
                        style: const TextStyle(
                          fontSize: 40,
                          color: Color(0xFF00796B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        patient['name'] ?? 'Paciente',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showEditDialog(context, patient, vm),
                        icon: const Icon(Icons.edit_note_rounded,
                            color: Colors.white70, size: 28),
                        tooltip: 'Editar Perfil',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Paciente Ativo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (patient['created_by'] == vm.authRepository.currentUser?.id) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.9),
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
                ],
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Visão Geral',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallInfoCard(
                          'Status',
                          'Conectado',
                          Icons.link,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSmallInfoCard(
                          'Estágio',
                          _formatStage(patient['stage']),
                          Icons.trending_up,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // New View Switcher Card
                  InkWell(
                    onTap: () {
                      vm.authRepository.setRoleOverride('patient', patientId: patient['id'].toString());
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.visibility_rounded, color: Colors.blue.shade700),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Visão do Paciente',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade900,
                                  ),
                                ),
                                Text(
                                  'Ver interface e jogar como este paciente',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.blue.shade300),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  const SizedBox(height: 16),

                  const SizedBox(height: 32),

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
                    ...vm.patientCaregivers.where((cg) {
                      final isProf = vm.authRepository.currentRole == 'professional';
                      if (!isProf) return true;
                      // If professional, only see self
                      return cg['id'] == vm.authRepository.currentUser?.id;
                    }).map((cg) => _buildCaregiverTile(cg)),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: patient['status'] == 'inactive'
                      ? ElevatedButton.icon(
                          onPressed: () => _showReactivationDialog(context, vm, patient),
                          icon: const Icon(Icons.restore_rounded),
                          label: const Text('Reativar Paciente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: () => _showDisconnectConfirm(context, patient, vm),
                          icon: const Icon(Icons.link_off, size: 20),
                          label: const Text('Desconectar Paciente'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.red.shade100),
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
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
        border: Border.all(color: isMe ? const Color(0xFF009688).withOpacity(0.3) : const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFF1F5F9),
            child: Text(initials, style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold)),
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
            isActive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: Text('Reativar ${patient['name']}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (vm.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                          child: Text(vm.errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      ),
                    const Text('Insira o código de vínculo para reativar o monitoramento.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 4),
                      decoration: const InputDecoration(border: OutlineInputBorder(), counterText: ""),
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
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
                                const SnackBar(content: Text('Reativado com sucesso!'), backgroundColor: Colors.green),
                              );
                            }
                          },
                    child: vm.isLoading ? const CircularProgressIndicator() : const Text('REATIVAR'),
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
