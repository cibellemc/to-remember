import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../view_models/caregiver_viewmodel.dart';

class PatientDetailsPage extends StatefulWidget {
  const PatientDetailsPage({super.key});

  @override
  State<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  String? _connectionCode;
  bool _isLoadingCode = false;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  Future<void> _loadCode() async {
    final vm = context.read<CaregiverViewModel>();
    final patient = vm.selectedPatient;
    if (patient == null) return;

    setState(() => _isLoadingCode = true);
    final code = await vm.getActiveCodeForPatient(patient['id'].toString());
    if (mounted) {
      setState(() {
        _connectionCode = code;
        _isLoadingCode = false;
      });
    }
  }

  Future<void> _generateNewCode() async {
    final vm = context.read<CaregiverViewModel>();
    final patient = vm.selectedPatient;
    if (patient == null) return;

    setState(() => _isLoadingCode = true);
    final code = await vm.refreshCodeForPatient(patient['id'].toString());
    if (mounted) {
      setState(() {
        _connectionCode = code;
        _isLoadingCode = false;
      });
    }
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
              builder: (context, vm, child) => TextButton(
                onPressed: vm.isLoading
                    ? null
                    : () async {
                        await vm.disconnectFromPatient(patient['id'].toString());
                        if (context.mounted) {
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
    final birthdateController = TextEditingController(text: patient['birthdate'] ?? patient['birth_date']);
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
                inputFormatters: [DateInputFormatter()],
              ),
              const SizedBox(height: 16),
              const Text('Estágio do Alzheimer', style: TextStyle(fontWeight: FontWeight.bold)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await vm.updatePatient(
                patientId: patient['id'].toString(),
                name: nameController.text,
                birthdate: birthdateController.text,
                stage: selectedStage,
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

  Widget _buildActionTile(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: Color(0xFFCBD5E1), size: 18),
        ],
      ),
    );
  }

  Widget _buildConnectionCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009688).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.qr_code_2_rounded,
                    color: Color(0xFF00897B), size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vincular Paciente',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B)),
                    ),
                    Text(
                      'Código para o paciente conectar',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (_connectionCode == null && !_isLoadingCode)
                IconButton(
                  onPressed: _generateNewCode,
                  icon: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF00897B)),
                  tooltip: 'Gerar novo código',
                ),
            ],
          ),
          if (_isLoadingCode)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: LinearProgressIndicator(
                  backgroundColor: Color(0xFFF1F5F9), color: Color(0xFF00897B)),
            )
          else if (_connectionCode != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: const Color(0xFF00897B).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        _connectionCode!,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00796B),
                          letterSpacing: 6,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _connectionCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Código copiado!'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Color(0xFF00796B),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.copy_rounded,
                          color: Color(0xFF00796B), size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off_rounded,
                    size: 12, color: Color(0xFF64748B)),
                SizedBox(width: 4),
                Text(
                  'Este código expira em 24 horas',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _generateNewCode,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Gerar Primeiro Código'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF00897B),
                  side: const BorderSide(color: Color(0xFF00897B)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
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
            // Header with Gradient and Avatar
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
                  const SizedBox(height: 32),

                  // Connection Code Section
                  const Text(
                    'Código de Vínculo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildConnectionCodeCard(),

                  const SizedBox(height: 32),

                  const Text(
                    'Atividade Recente',
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.videogame_asset_outlined,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Último Jogo',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                'Jogo da Memória',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          'Há 2h',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Ações Rápidas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionTile(
                    'Histórico de Atividades',
                    'Veja o desempenho do paciente',
                    Icons.history,
                    const Color(0xFF6366F1),
                  ),
                  const SizedBox(height: 12),
                  _buildActionTile(
                    'Plano de Cuidados',
                    'Configure lembretes e tarefas',
                    Icons.assignment_outlined,
                    const Color(0xFF0EA5E9),
                  ),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
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
}

class _StandardButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isPrimary;
  final VoidCallback onTap;

  const _StandardButton({
    required this.icon,
    required this.label,
    required this.color,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : Colors.white,
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: isPrimary ? 2 : 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : BorderSide(color: color.withOpacity(0.2)),
          ),
        ),
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
    var text = newValue.text;
    if (text.length < oldValue.text.length) return newValue;
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    if (text.length > 8) text = text.substring(0, 8);
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
