import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${vm.authRepository.currentUser?.userMetadata?['full_name'] ?? 'Cuidador'}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Acompanhe seus pacientes',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
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
        else ...[
          // Monitoramento Ativo
          if (vm.activePatients.isNotEmpty) ...[
            const Text(
              'Monitoramento Ativo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            ...vm.activePatients.map(
              (patient) => _buildPatientCard(context, patient, vm, primaryColor),
            ),
            const SizedBox(height: 24),
          ],

          _buildAddButton(context, vm, primaryColor),

          // Histórico de Pacientes (Archive)
          if (vm.inactivePatients.isNotEmpty) ...[
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Histórico de Pacientes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
              ),
            ),
            const Text(
              'Pacientes com vínculo desativado',
              style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            ...vm.inactivePatients.map(
              (patient) => _buildPatientCard(context, patient, vm, primaryColor,
                  isInactive: true),
            ),
            const SizedBox(height: 32),
          ],
        ],
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
    Color primaryColor, {
    bool isInactive = false,
  }) {
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
            color: isInactive
                ? Colors.grey.withOpacity(0.05)
                : primaryColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Opacity(
        opacity: isInactive ? 0.7 : 1.0,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isInactive
                ? null
                : () {
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
                        colors: isInactive
                            ? [Colors.grey.shade400, Colors.grey.shade500]
                            : [primaryColor.withOpacity(0.8), primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: isInactive
                              ? Colors.grey.withOpacity(0.3)
                              : primaryColor.withOpacity(0.3),
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
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
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
                                    color: const Color(0xFF009688)
                                        .withOpacity(0.3),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.star,
                                        color: Color(0xFF009688), size: 10),
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
                            if (!isComplete && !isInactive)
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
                              isInactive
                                  ? 'Monitoramento Pausado'
                                  : (stage != null
                                      ? 'Alzheimer ${stage[0].toUpperCase() + stage.substring(1)}'
                                      : 'Monitorando'),
                              style: TextStyle(
                                color: isInactive
                                    ? Colors.grey.shade500
                                    : (stage != null
                                        ? Colors.grey.shade600
                                        : primaryColor),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (!isInactive) ...[
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
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (isInactive)
                    TextButton.icon(
                      onPressed: () =>
                          vm.reactivatePatient(patient['id'].toString()),
                      icon: const Icon(Icons.restore_rounded, size: 20),
                      label: const Text('REATIVAR',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    )
                  else
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
      ),
    );
  }

  void _showConnectionDialog(
    BuildContext context,
    CaregiverViewModel vm,
    Color primaryColor,
  ) {
    int dialogStep = 0;
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
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                          onCompletarPerfil: () =>
                              setDialogState(() => dialogStep = 3),
                          onVincularExistente: () {
                            final manualProfiles = vm.connectedPatients
                                .where((p) => p['auth_id'] == null)
                                .toList();
                            if (manualProfiles.isEmpty) {
                              vm.setErrorMessage(
                                  'Nenhum perfil manual disponível para vincular.');
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
                          (stage) =>
                              setDialogState(() => selectedStage = stage),
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
          onChanged: (val) async {
            if (val.length == 6) {
              final patient = await vm.getPatientFromCode(val);
              if (patient != null) {
                onCodeValidated(patient);
              } else {
                vm.setErrorMessage('Código inválido ou expirado.');
              }
            }
          },
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('OU',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold))),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: onManualCreate,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: BorderSide(color: primaryColor),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            'CRIAR NOVO PACIENTE',
            style: TextStyle(
                color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Paciente nunca jogou ou não tem celular próprio',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildCodeValidatedStep(
    BuildContext context,
    CaregiverViewModel vm,
    Color primaryColor,
    Map<String, dynamic>? patient,
    {required VoidCallback onCompletarPerfil, 
     required VoidCallback onVincularExistente}
  ) {
    if (patient == null) return const SizedBox();
    
    final name = patient['name'] ?? 'Paciente';
    final isComplete = (patient['is_profile_complete'] == true) || 
                       (patient['name'] != null && patient['stage'] != null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: primaryColor,
                child: Text(name[0].toUpperCase(), 
                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(isComplete ? 'Perfil Completo' : 'Perfil Incompleto', 
                         style: TextStyle(fontSize: 12, 
                                        color: isComplete ? Colors.green : Colors.orange)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (isComplete)
          _buildConnectionActionCard(
            title: 'Conectar Agora',
            subtitle: 'O perfil já está completo. Vincular imediatamente.',
            icon: Icons.link_rounded,
            color: primaryColor,
            onTap: () async {
              final result = await vm.connectToPatient(patient['connection_code']);
              if (result != null && context.mounted) Navigator.pop(context);
            },
          )
        else ...[
          _buildConnectionActionCard(
            title: 'Vincular a Perfil Existente',
            subtitle: 'Se você já criou um perfil manual para este paciente.',
            icon: Icons.merge_type_rounded,
            color: Colors.blue,
            onTap: onVincularExistente,
          ),
          const SizedBox(height: 12),
          _buildConnectionActionCard(
            title: 'Completar novo perfil',
            subtitle: 'O paciente já joga e deseja manter o seu histórico.',
            icon: Icons.person_add_alt_1_rounded,
            color: Colors.orange,
            onTap: onCompletarPerfil,
          ),
        ],
      ],
    );
  }

  Widget _buildConnectionActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.5)),
          ],
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
    VoidCallback onBackToForm,
  ) {
    final manualProfiles = vm.connectedPatients
        .where((p) => p['auth_id'] == null)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Selecione o perfil manual que deseja vincular a este código.',
          style: TextStyle(color: Colors.blueGrey, fontSize: 13),
        ),
        const SizedBox(height: 16),
        ...manualProfiles.map((p) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text(p['name'][0].toUpperCase())),
            title: Text(p['name']),
            subtitle: Text('Criado em ${vm.authRepository.formatDateBR(p['added_at'])}'),
            trailing: const Icon(Icons.link_rounded),
            onTap: () async {
              final result = await vm.connectToPatient(code, targetPatientId: p['id'].toString());
              if (result != null && context.mounted) Navigator.pop(context);
            },
          ),
        )),
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
    Function(String?) onStageSelected,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dialogLabel('NOME COMPLETO'),
        TextField(
          controller: nameController,
          decoration: _dialogInputDecoration(primaryColor, 'Ex: Maria Oliveira'),
        ),
        const SizedBox(height: 20),
        _dialogLabel('DATA DE NASCIMENTO'),
        TextField(
          controller: birthdateController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            _DateInputFormatter(),
          ],
          decoration: _dialogInputDecoration(primaryColor, '00/00/0000'),
        ),
        const SizedBox(height: 20),
        _dialogLabel('ESTÁGIO DO ALZHEIMER'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            {'value': 'inicial', 'label': 'Inicial'},
            {'value': 'moderado', 'label': 'Moderado'},
            {'value': 'avancado', 'label': 'Avançado'},
          ].map((s) {
            final isSelected = selectedStage == s['value'];
            return ChoiceChip(
              label: Text(
                s['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              selected: isSelected,
              selectedColor: primaryColor,
              backgroundColor: Colors.grey.shade100,
              onSelected: (val) => onStageSelected(val ? s['value'] : null),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            );
          }).toList(),
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
    Future<void> Function() onSubmit,
  ) {
    return Row(
      children: [
        if (step > 0)
          Expanded(
            child: TextButton(
              onPressed: vm.isLoading ? null : onBack,
              child: const Text('Voltar',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
        if (step == 0)
          Expanded(
            child: TextButton(
              onPressed: vm.isLoading ? null : onBack,
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ),
        const SizedBox(width: 12),
        if (step == 3)
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: vm.isLoading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: vm.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('SALVAR',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
      ],
    );
  }

  InputDecoration _dialogInputDecoration(Color color, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.grey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _dialogLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
      ),
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
    if (name.isEmpty || stage == null || birthdate.length < 10) {
      vm.setErrorMessage('Por favor, preencha todos os campos corretamente.');
      return;
    }

    dynamic result;
    if (code.isNotEmpty) {
      // Completar perfil de paciente existente (vindo de código)
      result = await vm.connectToPatient(code);
      if (result != null) {
        // Agora salva os detalhes através do VM para atualizar o estado
        final patientId = result['id'].toString();
        await vm.updatePatient(
          patientId: patientId,
          name: name,
          birthdate: birthdate,
          stage: stage,
          isProfileComplete: true,
        );
      }
    } else {
      // Criar paciente totalmente novo (manual) através do VM
      result = await vm.createNewPatient(
        name: name,
        stage: stage,
        birthdate: birthdate,
      );
    }

    // Only close if we have a result AND no error occurred during secondary updates
    if (result != null && vm.errorMessage == null && context.mounted) {
      Navigator.pop(context);
    }
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
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
