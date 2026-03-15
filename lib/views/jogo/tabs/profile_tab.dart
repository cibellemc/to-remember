import 'dart:math' as math;
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
  static const disconnected = Color(0xFFE65100);
  static const disconnectedBg = Color(0xFFFFF3E0);

  static const radiusCard = 24.0;
  static const radiusButton = 16.0;
  static const radiusPill = 100.0;

  static const pagePadding = 20.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// QR CODE PAINTER
// ─────────────────────────────────────────────────────────────────────────────

class _QrCodePainter extends CustomPainter {
  final String data;
  static const int _modules = 21;

  const _QrCodePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / _modules;
    final paint = Paint()..color = _T.textPrimary;
    final bgPaint = Paint()..color = _T.surface;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final seed = data.codeUnits.fold(0, (a, b) => a ^ (b * 31));
    final rng = math.Random(seed);

    _drawFinderPattern(canvas, paint, cellSize, 0, 0);
    _drawFinderPattern(canvas, paint, cellSize, _modules - 7, 0);
    _drawFinderPattern(canvas, paint, cellSize, 0, _modules - 7);

    for (int row = 0; row < _modules; row++) {
      for (int col = 0; col < _modules; col++) {
        if (_isFinderArea(row, col)) continue;
        if (rng.nextBool()) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                col * cellSize + 0.5,
                row * cellSize + 0.5,
                cellSize - 1,
                cellSize - 1,
              ),
              const Radius.circular(1.5),
            ),
            paint,
          );
        }
      }
    }
  }

  void _drawFinderPattern(Canvas canvas, Paint paint, double cs, int startCol, int startRow) {
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        final isOuter = r == 0 || r == 6 || c == 0 || c == 6;
        final isInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
        if (isOuter || isInner) {
          canvas.drawRect(
            Rect.fromLTWH((startCol + c) * cs, (startRow + r) * cs, cs, cs),
            paint,
          );
        }
      }
    }
  }

  bool _isFinderArea(int row, int col) {
    final inTL = row < 8 && col < 8;
    final inTR = row < 8 && col >= _modules - 8;
    final inBL = row >= _modules - 8 && col < 8;
    return inTL || inTR || inBL;
  }

  @override
  bool shouldRepaint(_QrCodePainter old) => old.data != data;
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
    final repo = context.read<AuthRepository>();
    await Future.wait([
      repo.getPatientProfile(),
      repo.getActiveConnectionCode(),
      repo.getConnectedCaregivers(),
    ]);

    // If no active code, generate one automatically for the first time
    if (repo.connectionCode == null && mounted) {
      await repo.generateConnectionCode();
    }

    if (mounted) setState(() => _isLoading = false);
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

  Future<void> _refreshCode() async {
    setState(() => _isLoading = true);
    await context.read<AuthRepository>().generateConnectionCode();
    if (mounted) setState(() => _isLoading = false);
  }

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
    final code = repo.connectionCode;
    final caregivers = repo.connectedCaregivers;
    final isConnected = caregivers.isNotEmpty;
    final isMissingData = profile?['birthdate'] == null || profile?['stage'] == null;

    // Consolidate status
    String statusTitle;
    String statusSubtitle;
    Color statusIconColor;
    IconData statusIcon;
    Color statusBg;

    if (isMissingData) {
      statusTitle = 'Dados faltando';
      statusSubtitle = 'Seu perfil está incompleto. Peça ao seu cuidador para preencher.';
      statusIconColor = Colors.orange;
      statusIcon = Icons.warning_amber_rounded;
      statusBg = const Color(0xFFFFF9C4);
    } else if (isConnected) {
      statusTitle = 'Conectado à sua equipe';
      statusSubtitle = 'Seus cuidadores podem ver suas informações.';
      statusIconColor = _T.connected;
      statusIcon = Icons.link_rounded;
      statusBg = _T.connectedBg;
    } else {
      statusTitle = 'Aguardando cuidador';
      statusSubtitle = 'Compartilhe o código abaixo com quem cuida de você.';
      statusIconColor = _T.disconnected;
      statusIcon = Icons.link_off_rounded;
      statusBg = _T.disconnectedBg;
    }

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
                  child: _StatusBanner(
                    title: statusTitle,
                    subtitle: statusSubtitle,
                    icon: statusIcon,
                    color: statusIconColor,
                    backgroundColor: statusBg,
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: _SectionPadding(
                  top: 16,
                  child: _ProfileHeaderCard(
                    name: profile?['name'] ?? 'Usuário',
                    initials: _initials(profile?['name'] ?? 'U'),
                  ),
                ),
              ),

              if (code != null)
                SliverToBoxAdapter(
                  child: _SectionPadding(
                    top: 12,
                    child: _LinkingCodeCard(
                      code: code,
                      onCopy: () => _copyCode(code),
                      onRefresh: _refreshCode,
                    ),
                  ),
                ),

              if (isConnected) ...[
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
                    child: _CaregiversList(caregivers: caregivers),
                  ),
                ),
                if (code != null)
                  SliverToBoxAdapter(
                    child: _SectionPadding(
                      top: 12,
                      child: _CompactCodeCard(
                        code: code,
                        onCopy: () => _copyCode(code),
                      ),
                    ),
                  ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(_T.radiusCard),
        boxShadow: [
          BoxShadow(
            color: _T.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
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
                  color: _T.primary.withOpacity(0.35),
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
          const SizedBox(width: 20),
          Expanded(
            child: Column(
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
                Container(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _StatusBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(_T.radiusCard),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          _PulseDot(color: color),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.8).animate(_scale),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(0.2)),
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color),
          ),
        ],
      ),
    );
  }
}

class _LinkingCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;
  final VoidCallback onRefresh;

  const _LinkingCodeCard({
    required this.code,
    required this.onCopy,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _T.surface,
        borderRadius: BorderRadius.circular(_T.radiusCard),
        boxShadow: [
          BoxShadow(
            color: _T.primary.withOpacity(0.1),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2_rounded, color: _T.primaryDark, size: 26),
              SizedBox(width: 10),
              Text(
                'Seu Código de Vínculo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _T.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Compartilhe este código com seu cuidador\npara que ele possa se conectar a você.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: _T.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _T.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _T.primaryLight.withOpacity(0.4), width: 2),
            ),
            child: CustomPaint(size: const Size(160, 160), painter: _QrCodePainter(data: code)),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: _T.primarySurface,
              borderRadius: BorderRadius.circular(_T.radiusCard),
              border: Border.all(color: _T.primaryLight.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              children: [
                const Text(
                  'CÓDIGO',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _T.textSecondary, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  code,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: _T.primaryDark,
                    letterSpacing: 8,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TealButton(
                  icon: Icons.copy_rounded,
                  label: 'Copiar',
                  onTap: onCopy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Atualizar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _T.primarySurface,
                    foregroundColor: _T.primaryDark,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(_T.radiusButton),
                      side: const BorderSide(color: _T.primaryLight, width: 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_rounded, size: 12, color: _T.textSecondary),
              SizedBox(width: 4),
              Text(
                'O código expira em 10 minutos para sua segurança.',
                style: TextStyle(fontSize: 11, color: _T.textSecondary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactCodeCard extends StatelessWidget {
  final String code;
  final VoidCallback onCopy;

  const _CompactCodeCard({required this.code, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: _T.primarySurface,
        borderRadius: BorderRadius.circular(_T.radiusCard),
        border: Border.all(color: _T.primaryLight.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_rounded, color: _T.primaryDark, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Código de Vínculo',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.textSecondary, letterSpacing: 0.5),
                ),
                const SizedBox(height: 2),
                Text(
                  code,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: _T.primaryDark, letterSpacing: 4),
                ),
              ],
            ),
          ),
          _IconCopyButton(onTap: onCopy),
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
            color: _T.primary.withOpacity(0.06),
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
    final name = caregiver['name'] ?? 'Cuidador';
    final relation = caregiver['relationship'] ?? 'Cuidador';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _T.primary.withOpacity(0.15),
              border: Border.all(color: _T.primary.withOpacity(0.4), width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _T.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
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
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _T.connectedBg,
              borderRadius: BorderRadius.circular(_T.radiusPill),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, size: 13, color: _T.connected),
                SizedBox(width: 4),
                Text('Ativo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _T.connected)),
              ],
            ),
          ),
        ],
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
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: _T.primarySurface, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: _T.primaryDark),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _T.textPrimary)),
      ],
    );
  }
}

class _TealButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TealButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: _T.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.radiusButton)),
      ),
    );
  }
}

class _IconCopyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _IconCopyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: _T.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.copy_rounded, color: _T.primaryDark, size: 20),
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
