import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../view_models/caregiver_viewmodel.dart';
import '../home/patient_details_page.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CaregiverViewModel>();
    final primaryColor = const Color(0xFF009688);
    final secondaryColor = const Color(0xFFF0FDF4);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Olá, Cuidador',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Acompanhe seus pacientes',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
            Container(
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(Icons.refresh, color: primaryColor),
                onPressed: vm.fetchConnectedPatients,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        if (vm.isLoading && vm.connectedPatients.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 40),
              child: CircularProgressIndicator(),
            ),
          )
        else if (vm.connectedPatients.isEmpty)
          _buildEmptyState(context, vm, primaryColor)
        else
          ...vm.connectedPatients.map(
            (patient) => _buildPatientCard(context, patient, vm, primaryColor),
          ),
        const SizedBox(height: 32),
        if (vm.connectedPatients.isNotEmpty)
          _buildAddButton(context, vm, primaryColor),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    CaregiverViewModel vm,
    Color primaryColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.group_add_outlined, size: 64, color: primaryColor),
          ),
          const SizedBox(height: 24),
          const Text(
            'Inicie o monitoramento',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Conecte-se a um paciente para começar a acompanhar seu progresso e atividades.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          _buildAddButton(context, vm, primaryColor),
        ],
      ),
    );
  }

  Widget _buildAddButton(
    BuildContext context,
    CaregiverViewModel vm,
    Color primaryColor,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () => _showConnectionDialog(context, vm, primaryColor),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Conectar novo paciente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildPatientCard(
    BuildContext context,
    Map<String, dynamic> patient,
    CaregiverViewModel vm,
    Color primaryColor,
  ) {
    final name = patient['name'] ?? 'Sem nome';
    final stage = patient['stage'];
    final addedAt = patient['added_at'];
    final isComplete = patient['is_profile_complete'] ?? (patient['birthdate'] != null && patient['stage'] != null);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            vm.selectPatient(patient);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: vm,
                  child: const PatientDetailsPage(),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Initials Circle
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.8), primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (!isComplete)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.edit_note_rounded, size: 14, color: Colors.orange.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completar',
                                    style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.psychology_rounded, size: 15, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            stage != null ? 'Alzheimer $stage' : 'Monitorando',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Text(
                            'Conectado em ${_formatDate(addedAt)}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConnectionDialog(
    BuildContext context,
    CaregiverViewModel vm,
    Color primaryColor,
  ) {
    int dialogStep = 0; // 0: Choice, 1: Enter Code, 2: Create New
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final birthdateController = TextEditingController();
    String? selectedStage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: vm,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
            return Consumer<CaregiverViewModel>(
              builder: (context, vm, child) {
                Widget content = const SizedBox.shrink();
                String title = 'Conectar Paciente';

                // Base style for dialog text
                const labelStyle = TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                );

                if (dialogStep == 0) {
                  content = SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildOptionButton(
                          context,
                          icon: Icons.qr_code_scanner,
                          title: 'Já possui código',
                          subtitle: 'Vincular a um paciente que já usa o app',
                          onTap: () => setDialogState(() => dialogStep = 1),
                          primaryColor: primaryColor,
                        ),
                        const SizedBox(height: 16),
                        _buildOptionButton(
                          context,
                          icon: Icons.person_add_alt_1,
                          title: 'Criar novo perfil',
                          subtitle: 'Cadastrar um novo paciente agora',
                          onTap: () => setDialogState(() => dialogStep = 2),
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),
                  );
                } else if (dialogStep == 1) {
                  title = 'Inserir Código';
                  content = SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Peça o código de 6 dígitos que aparece no perfil do paciente.',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: codeController,
                          autofocus: true,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: primaryColor,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          decoration: _dialogInputDecoration(primaryColor, 'ABC123'),
                        ),
                      ],
                    ),
                  );
                } else if (dialogStep == 2) {
                  title = 'Novo Paciente';
                  content = SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nome do Paciente', style: labelStyle),
                          const SizedBox(height: 8),
                          TextField(
                            controller: nameController,
                            decoration: _dialogInputDecoration(primaryColor, 'Ex: Maria da Silva'),
                          ),
                          const SizedBox(height: 16),
                          const Text('Data de Nascimento', style: labelStyle),
                          const SizedBox(height: 8),
                          TextField(
                            controller: birthdateController,
                            decoration: _dialogInputDecoration(primaryColor, 'Ex: 01/01/1950'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              DateInputFormatter(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Fase do Alzheimer', style: labelStyle),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            decoration: _dialogInputDecoration(primaryColor, 'Selecione a fase'),
                            items: const [
                              DropdownMenuItem(value: 'inicial', child: Text('Inicial')),
                              DropdownMenuItem(value: 'moderado', child: Text('Moderado (Intermediário)')),
                              DropdownMenuItem(value: 'avancado', child: Text('Avançado')),
                            ],
                            onChanged: (val) => setDialogState(() => selectedStage = val),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return AlertDialog(
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (vm.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            vm.errorMessage!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      content,
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: vm.isLoading ? null : () {
                        if (dialogStep == 0) {
                          Navigator.pop(context);
                        } else {
                          setDialogState(() => dialogStep = 0);
                        }
                      },
                      child: Text(
                        dialogStep == 0 ? 'Fechar' : 'Voltar',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    if (dialogStep == 1 || dialogStep == 2)
                      ElevatedButton(
                        onPressed: vm.isLoading
                            ? null
                            : () async {
                                if (dialogStep == 1) {
                                  final patient = await vm.connectToPatient(
                                      codeController.text);
                                  if (vm.errorMessage == null &&
                                      context.mounted) {
                                    Navigator.pop(context);
                                    if (patient != null &&
                                        (patient['birth_date'] == null ||
                                            patient['stage'] == null)) {
                                      _showProfileCompletionDialog(
                                          context, vm, patient, primaryColor);
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Conectado com sucesso!')),
                                      );
                                    }
                                  }
                                } else if (dialogStep == 2) {
                            if (nameController.text.trim().isEmpty) {
                              setDialogState(() {
                                vm.setErrorMessage('Por favor, informe o nome do paciente.');
                              });
                              return;
                            }
                            if (selectedStage == null) {
                              setDialogState(() {
                                vm.setErrorMessage('Por favor, selecione a fase do Alzheimer.');
                              });
                              return;
                            }

                            final patientId = await vm.createNewPatient(
                              name: nameController.text,
                              stage: selectedStage,
                              birthdate: birthdateController.text,
                            );
                            if (patientId != null && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Paciente criado com sucesso!')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: vm.isLoading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(dialogStep == 1 ? 'Conectar' : 'Adicionar'),
                      ),
                  ],
                );
              },
            );
          },
        ),
      );
    },
  );
}

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  InputDecoration _dialogInputDecoration(Color primaryColor, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade100)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor, width: 2)),
    );
  }

  void _showProfileCompletionDialog(
    BuildContext context,
    CaregiverViewModel vm,
    Map<String, dynamic> patient,
    Color primaryColor,
  ) {
    final nameController = TextEditingController(text: patient['name']);
    final birthdateController = TextEditingController(text: patient['birth_date'] ?? patient['birthdate']);
    String? selectedStage = patient['stage'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Completar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quase lá! Para melhor acompanhamento, complete os dados do paciente.', 
                style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 20),
              const Text('Nome', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: _dialogInputDecoration(primaryColor, 'Nome'),
              ),
              const SizedBox(height: 16),
              const Text('Data de Nascimento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: birthdateController,
                decoration: _dialogInputDecoration(primaryColor, 'DD/MM/YYYY'),
                keyboardType: TextInputType.number,
                inputFormatters: [DateInputFormatter()],
              ),
              const SizedBox(height: 16),
              const Text('Fase do Alzheimer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedStage,
                decoration: _dialogInputDecoration(primaryColor, 'Selecione'),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Pular')),
          ElevatedButton(
            onPressed: () async {
              await vm.updatePatient(
                patientId: patient['id'].toString(),
                name: nameController.text,
                birthdate: birthdateController.text,
                stage: selectedStage,
              );
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only allow digits related logic
    final newText = newValue.text;

    // If deleting, allow default behavior
    if (newText.length < oldValue.text.length) {
      return newValue;
    }

    // Filter to digits only first
    var text = newText.replaceAll(RegExp(r'[^0-9]'), '');
    
    // Limit to 8 digits (DDMMYYYY)
    if (text.length > 8) text = text.substring(0, 8);

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) {
        buffer.write('/');
      }
    }

    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
