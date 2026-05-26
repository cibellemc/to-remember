import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../data/repositories/auth_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

abstract class _T {
  static const primary = Color(0xFF009688);
  static const primaryDark = Color(0xFF00796B);
  static const primaryLight = Color(0xFF4DB6AC);
  static const primarySurface = Color(0xFFE0F2F1);

  static const background = Color(0xFFF4F7F6);
  static const surface = Color(0xFFFFFFFF);

  static const textPrimary = Color(0xFF1A2E2C);
  static const textSecondary = Color(0xFF5A7571);

  static const connected = Color(0xFF2E7D32);
  static const connectedBg = Color(0xFFE8F5E9);

  static const radiusCard = 24.0;
  static const radiusPill = 100.0;

  static const pagePadding = 20.0;
}


// ─────────────────────────────────────────────────────────────────────────────
// PROFILE TAB
// ─────────────────────────────────────────────────────────────────────────────

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final repo = context.read<AuthRepository>();
      await Future.wait([
        repo.getPatientProfile(),
        repo.getConnectedCaregivers(),
      ]);
      // After profile is loaded, ensure a code exists
      if (repo.connectionCode == null) {
        await repo.getActiveConnectionCode();
        if (repo.connectionCode == null) {
          await repo.generateConnectionCode();
        }
      }
    } catch (e) {
      debugPrint('Error loading patient data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }


// REMOVED: _showBilateralConnectionDialog as patients only share their code now

// REMOVED: _showProfileCompletionDialog as profiles are completed by caregivers or separately

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Código copiado!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: _T.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.radiusPill)),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<AuthRepository>();
    final profile = repo.patientProfile;
    final caregivers = repo.connectedCaregivers;
    final isConnected = caregivers.isNotEmpty;


    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _T.background,
        body: Center(child: CircularProgressIndicator(color: _T.primary)),
      );
    }

    return Scaffold(
      backgroundColor: _T.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _SectionPadding(
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Meu Perfil',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _T.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _T.primary,
                          borderRadius: BorderRadius.circular(_T.radiusPill),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.favorite_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'To Remember',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _SectionPadding(
                  top: 16,
                  child: repo.realRole != 'professional' ? Column(
                    children: [
                      _ProfileHeaderCard(
                        name: profile?['name'] ?? 'Usuário',
                        initials: _initials(profile?['name'] ?? 'U'),
                      ),
                      if (profile != null) ...[
                        const SizedBox(height: 16),
                        _CompactCodeCard(
                          key: const Key('card_codigo_vinculo'),
                          code: repo.connectionCode ?? '------',
                          suffix: profile['linking_suffix'] ?? '----',
                          onCopy: () {
                            if (repo.connectionCode != null) {
                              _copyCode('${repo.connectionCode} #${profile['linking_suffix'] ?? ''}');
                            }
                          },
                        ),
                      ],
                    ],
                  ) : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Acesso Restrito',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _T.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Como profissional, você não tem acesso aos detalhes de perfil e equipe deste paciente.',
                        style: TextStyle(fontSize: 15, color: _T.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),

              if (repo.realRole != 'professional')
                const SliverToBoxAdapter(
                  child: _SectionPadding(
                    top: 24,
                    child: _SectionHeader(
                      icon: Icons.people_alt_rounded,
                      label: 'Minha Equipe de Cuidado',
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: _SectionPadding(
                  top: 12,
                  child: repo.realRole != 'professional'
                      ? (isConnected
                          ? Column(
                              children: [
                                _CaregiversList(
                                  caregivers: caregivers,
                                ),
                                const SizedBox(height: 24),
                              ],
                            )
                          : const _EmptyConnectionsBanner())
                      : const SizedBox.shrink(),
                ),
              ),

              if (repo.roleOverride != null)
                SliverToBoxAdapter(
                  child: _SectionPadding(
                    top: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionHeader(
                          icon: Icons.admin_panel_settings_rounded,
                          label: 'Modo Gestor',
                        ),
                        const SizedBox(height: 12),
                        _buildSettingsAction(
                          context,
                          key: const Key('btn_sair_visao_paciente'),
                          icon: Icons.settings_backup_restore_rounded,
                          label: 'Voltar para Visão de Gestor',
                          color: _T.primaryDark,
                          onTap: () => _handleSwitchBackToCaregiver(context, repo),
                        ),
                      ],
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
  void _handleSwitchBackToCaregiver(BuildContext context, AuthRepository repo) {
    final controller = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.radiusCard)),
            title: const Text(
              'Confirmar PIN',
              style: TextStyle(fontWeight: FontWeight.w800, color: _T.textPrimary),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Digite seu PIN para voltar para a visão do gestor.',
                  style: TextStyle(color: _T.textSecondary, fontSize: 15),
                ),
                const SizedBox(height: 24),
                TextField(
                  key: const Key('input_pin'),
                  controller: controller,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (errorMessage != null) {
                      setState(() => errorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••',
                    hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 8),
                    errorText: errorMessage,
                    errorStyle: const TextStyle(fontWeight: FontWeight.w600),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: _T.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: _T.textSecondary),
                child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.length < 4) return;
                  
                  final ok = await repo.verifySecurityPin(controller.text);
                  if (ok) {
                    repo.setRoleOverride(null);
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  } else {
                    setState(() {
                      errorMessage = 'PIN incorreto!';
                      controller.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _T.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingsAction(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(_T.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(_T.radiusCard),
          border: Border.all(color: color.withValues(alpha:0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color.withValues(alpha:0.5)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String initials;

  const _ProfileHeaderCard({required this.name, required this.initials});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final isLargeFont = textScale > 1.3;

    // FIX #1: Avatar com semântica — o TalkBack vai ignorar as iniciais visuais
    // e anunciar corretamente o nome completo do perfil.
    final avatar = Semantics(
      label: 'Foto de perfil de $name',
      excludeSemantics: true,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF26A69A), Color(0xFF00796B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _T.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bom ver você,',
          style: TextStyle(
            fontSize: 14,
            color: _T.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _T.textPrimary,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        // FIX #2: Badge de papel com semântica — agrupa ícone + texto em
        // uma única leitura contextual para o TalkBack.
        Semantics(
          label: 'Papel: Paciente verificado',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _T.primarySurface,
              borderRadius: BorderRadius.circular(_T.radiusPill),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 14, color: _T.primaryDark),
                SizedBox(width: 5),
                Text(
                  'Paciente',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _T.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(_T.radiusCard),
        boxShadow: [
          BoxShadow(
            color: _T.primary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isLargeFont
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(height: 16),
                infoColumn,
              ],
            )
          : Row(
              children: [
                avatar,
                const SizedBox(width: 20),
                Expanded(child: infoColumn),
              ],
            ),
    );
  }
}


class _EmptyConnectionsBanner extends StatelessWidget {
  const _EmptyConnectionsBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(_T.radiusCard),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.04),
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
            child: const Icon(Icons.group_add_outlined, size: 64, color: _T.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Inicie sua equipe',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Conecte-se a um cuidador para compartilhar seu progresso e receber apoio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _T.textSecondary,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // REMOVED: _buildAddButton call as patients only share their code now
        ],
      ),
    );
  }
}

// REMOVED: _buildAddButton method


// REMOVED: _dialogInputDecoration as it's no longer used in ProfileTab



 class _CompactCodeCard extends StatelessWidget {
  final String code;
  final String suffix;
  final VoidCallback onCopy;

  const _CompactCodeCard({
    super.key,
    required this.code,
    required this.suffix,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final isLargeFont = textScale > 1.3;

    final qrIcon = const Icon(Icons.qr_code_rounded, color: _T.primaryDark, size: 28);

    final codeSection = Column(
      crossAxisAlignment: isLargeFont ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const Text(
          'Código de Vínculo',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.textSecondary, letterSpacing: 0.5),
        ),
        const SizedBox(height: 2),
        Semantics(
          label: 'Código de vínculo: ${code.split("").join(" ")}, sufixo: ${suffix.split("").join(" ")}',
          excludeSemantics: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: isLargeFont ? Alignment.center : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  code,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _T.primaryDark, letterSpacing: 4),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _T.primaryDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$suffix',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _T.primaryDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final copyButton = _IconCopyButton(onTap: onCopy);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _T.primarySurface,
        borderRadius: BorderRadius.circular(_T.radiusCard),
        border: Border.all(color: _T.primaryLight.withValues(alpha: 0.4), width: 1.5),
      ),
      child: isLargeFont
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    qrIcon,
                    const SizedBox(width: 8),
                    const Text(
                      'Código do Paciente',
                      style: TextStyle(fontWeight: FontWeight.bold, color: _T.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                codeSection,
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onCopy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _T.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 20),
                    label: const Text(
                      'Copiar Código',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            )
          : Row(
              children: [
                qrIcon,
                const SizedBox(width: 14),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: codeSection,
                  ),
                ),
                copyButton,
              ],
            ),
    );
  }
}

class _CaregiversList extends StatelessWidget {
  final List<Map<String, dynamic>> caregivers;

  const _CaregiversList({required this.caregivers});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(_T.radiusCard),
        boxShadow: [
          BoxShadow(
            color: _T.primary.withValues(alpha:0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_T.radiusCard),
        child: Column(
          children: [
            for (int i = 0; i < caregivers.length; i++) ...[
              _CaregiverTile(caregiver: caregivers[i]),
              if (i < caregivers.length - 1)
                const Divider(height: 1, indent: 72, endIndent: 20, color: Color(0xFFECF3F2)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CaregiverTile extends StatelessWidget {
  final Map<String, dynamic> caregiver;

  const _CaregiverTile({required this.caregiver});

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final isLargeFont = textScale > 1.3;

    final name = caregiver['name'] ?? 'Membro';
    final role = caregiver['role'] as String?;
    final relation = role == 'professional' ? 'Profissional' : 'Familiar';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final avatar = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _T.primary.withValues(alpha:0.15),
        border: Border.all(color: _T.primary.withValues(alpha:0.4), width: 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _T.primary),
        ),
      ),
    );

    final badge = _CaregiverStatusBadge(status: caregiver['status'] ?? 'active');

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _T.textPrimary),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            const Icon(Icons.badge_rounded, size: 14, color: _T.textSecondary),
            const SizedBox(width: 4),
            Text(
              relation,
              style: const TextStyle(fontSize: 14, color: _T.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        if (isLargeFont) ...[
          const SizedBox(height: 8),
          badge,
        ],
      ],
    );

    // FIX #5: O tile inteiro é agrupado em um único nó semântico.
    // Sem isso, o TalkBack leria: "M" (inicial), "Nome", "Familiar", "Ativo"
    // — quatro anúncios separados sem contexto. Agora lê tudo de uma vez.
    final statusLabel = (caregiver['status'] ?? 'active') == 'active' ? 'ativo' : 'pausado';
    return Semantics(
      label: '$name, $relation, vínculo $statusLabel',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: isLargeFont
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 16),
                  Expanded(child: infoColumn),
                ],
              )
            : Row(
                children: [
                  avatar,
                  const SizedBox(width: 16),
                  Expanded(child: infoColumn),
                  badge,
                ],
              ),
      ),
    );
  }
}

class _CaregiverStatusBadge extends StatelessWidget {
  final String status;
  const _CaregiverStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    // FIX #6: Badge de status com label contextual. Sem isso, o TalkBack
    // anuncia apenas "Ativo" ou "Pausado" sem contexto de que é o status
    // do vínculo daquele membro da equipe. Este widget é marcado com
    // excludeSemantics pois o tile pai já agrega o status no seu label.
    return Semantics(
      label: 'Status do vínculo: ${isActive ? 'ativo' : 'pausado'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? _T.connectedBg : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(_T.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle_rounded : Icons.pause_circle_filled_rounded,
              size: 13,
              color: isActive ? _T.connected : Colors.grey.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              isActive ? 'Ativo' : 'Pausado',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isActive ? _T.connected : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    // FIX #3: Agrupa ícone + texto em uma única leitura semântica.
    // Sem isso, o TalkBack anunciaria o ícone separadamente ("ícone sem nome").
    // O container de ícone agora usa padding em vez de tamanho fixo para
    // escalar corretamente com zoom de acessibilidade.
    return Semantics(
      header: true,
      label: label,
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: _T.primarySurface, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: _T.primaryDark),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _T.textPrimary)),
        ],
      ),
    );
  }
}


class _IconCopyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _IconCopyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    // FIX #4: Substituído GestureDetector por Semantics + InkWell.
    // GestureDetector é invisível para leitores de tela — não é anunciado
    // como botão e não pode ser ativado por toque de acessibilidade.
    // InkWell já aparece como elemento interativo na árvore semântica.
    return Semantics(
      button: true,
      label: 'Copiar código de vínculo',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _T.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.copy_rounded, color: _T.primaryDark, size: 20),
        ),
      ),
    );
  }
}

class _SectionPadding extends StatelessWidget {
  final Widget child;
  final double top;

  const _SectionPadding({required this.child, this.top = 12});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.fromLTRB(_T.pagePadding, top, _T.pagePadding, 0), child: child);
  }
}
