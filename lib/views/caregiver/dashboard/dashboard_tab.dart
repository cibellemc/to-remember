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
                Text(
                  'Olá, ${vm.authRepository.currentUser?.userMetadata?['full_name'] ?? 'Cuidador'}',
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
            decoration: const BoxDecoration(
              color: Color(0xFFF0FDF4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_add_outlined,
              size: 64,
              color: primaryColor,
            ),
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
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 24),
            SizedBox(width: 12),
            Text(
              'Conectar novo paciente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
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
    final isComplete =
        (patient['is_profile_complete'] == true) ||
        (patient['name'] != null && patient['stage'] != null);
    final isCreator =
        patient['created_by'] == vm.authRepository.currentUser?.id;

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
                          if (isCreator)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2F1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF009688,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Color(0xFF009688),
                                    size: 10,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Criador',
                                    style: TextStyle(
                                      color: Color(0xFF009688),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 8),
                          if (!isComplete)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    size: 14,
                                    color: Colors.orange.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Completar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.psychology_rounded,
                            size: 15,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            stage != null
                                ? 'Alzheimer ${stage[0].toUpperCase() + stage.substring(1)}'
                                : 'Monitorando',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Conectado em ${vm.authRepository.formatDateBR(addedAt)}',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
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
    int dialogStep = 0; // 0: Code Entry, 1: Selection, 2: Form
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final birthdateController = TextEditingController();
    String? selectedStage;
    Map<String, dynamic>? patientFromCode;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ChangeNotifierProvider.value(
              value: vm,
              child: StatefulBuilder(
                builder: (context, setDialogState) {
                  return Consumer<CaregiverViewModel>(
                    builder: (context, vm, child) {
                      String title = 'Conectar Paciente';
                      if (dialogStep == 1) title = 'Código Validado!';
                      if (dialogStep == 2) title = 'Vincular Conta';
                      if (dialogStep == 3) {
                        title = codeController.text.isNotEmpty
                            ? 'Completar Perfil'
                            : 'Novo Cadastro';
                      }

                      Widget stepContent;
                      if (dialogStep == 0) {
                        stepContent = _buildCodeEntryStep(
                          context,
                          vm,
                          primaryColor,
                          codeController,
                          (patient) {
                            patientFromCode = patient;
                            setDialogState(() => dialogStep = 1);
                          },
                          onManualCreate: () {
                            codeController.clear();
                            setDialogState(() => dialogStep = 3);
                          },
                        );
                      } else if (dialogStep == 1) {
                        stepContent = _buildCodeValidatedStep(
                          context,
                          vm,
                          primaryColor,
                          patientFromCode,
                          onCompletarPerfil: () => setDialogState(() => dialogStep = 3),
                          onVincularExistente: () {
                            final manualProfiles = vm.connectedPatients
                                .where((p) => p['auth_id'] == null)
                                .toList();
                            if (manualProfiles.isEmpty) {
                              vm.setErrorMessage('Nenhum perfil manual disponível para vincular.');
                            } else {
                              setDialogState(() => dialogStep = 2);
                            }
                          },
                        );
                      } else if (dialogStep == 2) {
                        stepContent = _buildSelectionStep(
                          context,
                          vm,
                          primaryColor,
                          patientFromCode,
                          codeController.text,
                          () => setDialogState(() => dialogStep = 3),
                        );
                      } else {
                        stepContent = _buildFormStep(
                          context,
                          vm,
                          primaryColor,
                          nameController,
                          birthdateController,
                          selectedStage,
                          (stage) => setDialogState(() => selectedStage = stage),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            if (vm.errorMessage != null) _buildErrorBox(vm),
                            Flexible(
                              child: SingleChildScrollView(child: stepContent),
                            ),
                            const SizedBox(height: 24),
                            _buildActionButtons(
                              context,
                              vm,
                              primaryColor,
                              dialogStep,
                              () {
                                if (dialogStep == 0) {
                                  Navigator.pop(context);
                                } else {
                                  vm.clearError();
                                  setDialogState(() => dialogStep = 0);
                                }
                              },
                              () async {
                                if (dialogStep == 3) {
                                  await _handleFormSubmit(
                                    context,
                                    vm,
                                    codeController.text,
                                    nameController.text,
                                    selectedStage,
                                    birthdateController.text,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorBox(CaregiverViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              vm.errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeEntryStep(
    BuildContext context,
    CaregiverViewModel vm,
    Color primaryColor,
    TextEditingController controller,
    Function(Map<String, dynamic>) onCodeValidated, {
    required VoidCallback onManualCreate,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Insira o código gerado no celular do paciente para vincular as contas.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.blueGrey, fontSize: 14),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: controller,
          maxLength: 6,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.text,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
            color: primaryColor,
          ),
          textCapitalization: TextCapitalization.characters,
          decoration: _dialogInputDecoration(primaryColor, 'CODE6').copyWith(
            counterText: "",
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: vm.isLoading
              ? null
              : () async {
                  if (controller.text.length < 6) {
                    vm.setErrorMessage('O código deve ter 6 caracteres.');
                    return;
                  }
                  final patient = await vm.getPatientFromCode(controller.text);
                  if (patient == null) {
                    vm.setErrorMessage('Código inválido ou expirado.');
                    return;
                  }

                  // Se o perfil já estiver completo, vincula direto
                  if (patient['is_profile_complete'] == true) {
                    final successResult = await vm.connectToPatient(controller.text);
                    if (successResult != null && context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Paciente vinculado com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } else {
                    onCodeValidated(patient);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: vm.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Validar Código', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OU',
                style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        _buildOptionCard(
          icon: Icons.person_add_alt_1_rounded,
          title: 'Criar novo paciente',
          subtitle: 'Paciente nunca jogou ou não tem celular próprio',
          onTap: onManualCreate,
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildCodeValidatedStep(
    BuildContext context,
    CaregiverViewModel vm,
    Color primaryColor,
    Map<String, dynamic>? patientFromCode, {
    required VoidCallback onCompletarPerfil,
    required VoidCallback onVincularExistente,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            children: [
              const TextSpan(text: 'O código pertence a '),
              TextSpan(
                text: patientFromCode?['name'] ?? 'Paciente',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const TextSpan(text: '. O que deseja fazer?'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildOptionCard(
          icon: Icons.person_add_alt_rounded,
          title: 'Completar perfil',
          subtitle: 'Preencher nome, nascimento e estágio',
          onTap: onCompletarPerfil,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          icon: Icons.group_add_rounded,
          title: 'Vincular a perfil existente',
          subtitle: 'Somar a conta de um paciente já cadastrado',
          onTap: onVincularExistente,
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color primaryColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28, color: primaryColor),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionStep(
    BuildContext context,
    CaregiverViewModel vm,
    Color primaryColor,
    Map<String, dynamic>? patientFromCode,
    String code,
    VoidCallback onNewSelected,
  ) {
    final manualProfiles =
        vm.connectedPatients.where((p) => p['auth_id'] == null).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
            children: [
              const TextSpan(text: 'Deseja somar a conta de '),
              TextSpan(
                text: '${patientFromCode?['name'] ?? 'Paciente'}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const TextSpan(text: ' a qual perfil já existente?'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...manualProfiles.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Text(p['name']?[0] ?? 'P', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                ),
                title: Text(p['name'] ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Selecionar este perfil'),
                onTap: () async {
                  final success = await vm.connectToPatient(code, targetPatientId: p['id'].toString());
                  if (success != null && context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Perfis vinculados com sucesso!')),
                    );
                  }
                },
              ),
            )),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onNewSelected,
          icon: const Icon(Icons.add),
          label: const Text('VINCULAR A UM NOVO PERFIL'),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildFormStep(
    BuildContext context,
    CaregiverViewModel vm,
    Color primaryColor,
    TextEditingController nameController,
    TextEditingController birthdateController,
    String? selectedStage,
    Function(String?) onStageChanged,
  ) {
    const labelStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Preencha as informações para completar o prontuário do paciente.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const Text('NOME COMPLETO', style: labelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          decoration: _dialogInputDecoration(primaryColor, 'Ex: Maria da Silva'),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 16),
        const Text('DATA DE NASCIMENTO', style: labelStyle),
        const SizedBox(height: 8),
        TextField(
          controller: birthdateController,
          decoration: _dialogInputDecoration(primaryColor, 'DD/MM/AAAA'),
          keyboardType: TextInputType.number,
          inputFormatters: [DateInputFormatter()],
        ),
        const SizedBox(height: 16),
        const Text('ESTÁGIO DO ALZHEIMER', style: labelStyle),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedStage,
          decoration: _dialogInputDecoration(primaryColor, 'Selecione o estágio'),
          items: const [
            DropdownMenuItem(value: 'inicial', child: Text('Inicial')),
            DropdownMenuItem(value: 'moderado', child: Text('Moderado')),
            DropdownMenuItem(value: 'avancado', child: Text('Avançado')),
          ],
          onChanged: onStageChanged,
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    CaregiverViewModel vm,
    Color primaryColor,
    int step,
    VoidCallback onBack,
    VoidCallback onSubmit,
  ) {
    if (step == 0) {
      return TextButton(
        onPressed: onBack,
        child: Text('CANCELAR', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: vm.isLoading ? null : onBack,
            child: Text('VOLTAR', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 16),
        if (step == 3)
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: vm.isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: vm.isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SALVAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Future<void> _handleFormSubmit(
    BuildContext context,
    CaregiverViewModel vm,
    String code,
    String name,
    String? stage,
    String birthdate,
  ) async {
    if (name.trim().isEmpty) {
      vm.setErrorMessage('O nome é obrigatório.');
      return;
    }
    if (stage == null) {
      vm.setErrorMessage('Selecione o estágio.');
      return;
    }

    if (code.isNotEmpty) {
      final connected = await vm.connectToPatient(code);
      if (connected != null) {
        await vm.updatePatient(
          patientId: connected['id'].toString(),
          name: name,
          stage: stage,
          birthdate: birthdate,
          isProfileComplete: true,
        );

        if (vm.errorMessage == null && context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paciente vinculado e prontuário salvo!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } else {
      final patientId = await vm.createNewPatient(
        name: name,
        stage: stage,
        birthdate: birthdate,
      );
      if (patientId != null && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil criado com sucesso!')),
        );
      }
    }
  }

  InputDecoration _dialogInputDecoration(Color primaryColor, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade400,
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade100),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
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
    final newText = newValue.text;
    if (newText.length < oldValue.text.length) return newValue;
    var text = newText.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) text = text.substring(0, 8);
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i == 1 || i == 3) && i != text.length - 1) buffer.write('/');
    }
    final formattedText = buffer.toString();
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
