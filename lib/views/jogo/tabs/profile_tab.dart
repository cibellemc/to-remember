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
                  child: Column(
                    children: [
                      _ProfileHeaderCard(
                        name: profile?['name'] ?? 'Usuário',
                        initials: _initials(profile?['name'] ?? 'U'),
                      ),
                      if (profile != null) ...[
                        const SizedBox(height: 16),
                        _CompactCodeCard(
                          code: repo.connectionCode ?? '------',
                          onCopy: () {
                            if (repo.connectionCode != null) {
                              _copyCode(repo.connectionCode!);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

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
                  child: isConnected
                      ? Column(
                          children: [
                            _CaregiversList(caregivers: caregivers),
                            const SizedBox(height: 24),
                            // REMOVED: Conectar novo cuidador button as patients only share their code now
                          ],
                        )
                      : const _EmptyConnectionsBanner(),
                ),
              ),

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
