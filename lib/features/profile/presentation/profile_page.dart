import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as du;
import '../../../shared/widgets/avatar_initials.dart';
import '../../../shared/widgets/dgt_app_bar.dart';
import '../../auth/domain/auth_provider.dart';
import '../data/employee_perfil_model.dart';
import '../domain/profile_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user         = ref.watch(currentUserProvider);
    final profile      = ref.watch(currentProfileProvider);
    final perfilAsync  = ref.watch(myEmployeePerfilProvider);

    final name     = user?.name ?? 'Usuário';
    final username = user?.username ?? '';
    final role     = user?.role ?? 'employee';

    final showTopPerformer = profile?.isHR == true || profile?.isLeader == true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: DgtAppBar.simple(title: 'Perfil'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Identity card ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                AvatarInitials(name: name, size: 56, fontSize: 18),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      const SizedBox(height: 3),
                      Text('@$username',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.statusAtRiskBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _roleLabel(role),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.statusAtRisk),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Complementary profile ────────────────────────────────────────
          perfilAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const _InfoNotFound(),
            data: (perfil) {
              if (perfil == null) return const _InfoNotFound();
              return _PerfilCard(
                perfil: perfil,
                showTopPerformer: showTopPerformer,
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Actions ──────────────────────────────────────────────────────
          _ProfileAction(
            icon: Icons.logout_rounded,
            label: 'Sair',
            color: AppColors.statusBehind,
            onTap: () => ref.read(authStateProvider.notifier).logout(),
          ),

          const SizedBox(height: 24),

          // ── Version ──────────────────────────────────────────────────────
          Center(
            child: Text(
              'v1.0.0 · ${AppConfig.buildDate}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textDisabled,
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  static String _roleLabel(String role) {
    switch (role) {
      case 'leader': return 'Gestor';
      case 'hr':     return 'RH';
      default:       return 'Colaborador';
    }
  }
}

// ── Perfil complementar card ──────────────────────────────────────────────────

class _PerfilCard extends StatelessWidget {
  final EmployeePerfil perfil;
  final bool showTopPerformer;

  const _PerfilCard({required this.perfil, required this.showTopPerformer});

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRow>[
      _InfoRow(label: 'Tipo', value: perfil.personTypeLabel),
      if (perfil.careerLevel.isNotEmpty)
        _InfoRow(label: 'Nível de carreira', value: perfil.careerLevel),
      if (perfil.function.isNotEmpty)
        _InfoRow(label: 'Função', value: perfil.function),
      if (perfil.hiringDate != null)
        _InfoRow(label: 'Data de admissão', value: du.formatDate(perfil.hiringDate!)),
      if (perfil.eMailCelular?.isNotEmpty == true)
        _InfoRow(label: 'E-mail / Celular', value: perfil.eMailCelular!),
      if (perfil.classificacationLastCycle.isNotEmpty)
        _InfoRow(label: 'Classificação (último ciclo)', value: _classLabel(perfil.classificacationLastCycle)),
      if (showTopPerformer)
        _InfoRow(label: 'Top Performer', value: perfil.topPerformer ? 'Sim' : 'Não'),
    ];

    if (rows.isEmpty) return const _InfoNotFound();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informações profissionais',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, color: AppColors.border),
            rows[i],
          ],
        ],
      ),
    );
  }

  static String _classLabel(String raw) {
    switch (raw) {
      case 'aboveLevel': return 'Acima do nível';
      case 'atLevel':    return 'No nível';
      case 'belowLevel': return 'Abaixo do nível';
      default:           return raw;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _InfoNotFound extends StatelessWidget {
  const _InfoNotFound();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: const Text(
        'Perfil complementar não encontrado.',
        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
}

// ── Action item ───────────────────────────────────────────────────────────────

class _ProfileAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: c)),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.lightGray, size: 18),
          ],
        ),
      ),
    );
  }
}
