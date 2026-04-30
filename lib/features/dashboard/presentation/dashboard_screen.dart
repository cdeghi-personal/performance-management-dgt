import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as du;
import '../../auth/domain/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isManager = ref.watch(isManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Olá, ${user?.name.split(' ').first ?? 'usuário'}'),
            Text(
              du.currentCycleLabel(),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'Ciclo ${du.currentCycleLabel()}'),
          const SizedBox(height: 12),
          Row(
            children: [
              _KpiCard(
                label: 'Metas Ativas',
                value: '—',
                icon: Icons.flag_outlined,
                color: AppColors.primary,
                onTap: () => context.go('/goals'),
              ),
              const SizedBox(width: 12),
              _KpiCard(
                label: 'Feedbacks',
                value: '—',
                icon: Icons.forum_outlined,
                color: AppColors.accent,
                onTap: () => context.go('/feedback'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _KpiCard(
                label: 'Avaliação',
                value: '—',
                icon: Icons.assessment_outlined,
                color: AppColors.statusAtRisk,
                onTap: () => context.go('/evaluations'),
              ),
              const SizedBox(width: 12),
              if (isManager)
                _KpiCard(
                  label: 'Reuniões',
                  value: '—',
                  icon: Icons.groups_outlined,
                  color: AppColors.primaryLight,
                  onTap: () => context.go('/meetings'),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Acesso Rápido'),
          const SizedBox(height: 12),
          _QuickAction(
            icon: Icons.add_task,
            label: 'Nova Meta',
            subtitle: 'Registrar meta do ciclo atual',
            onTap: () => context.go('/goals/new'),
          ),
          _QuickAction(
            icon: Icons.feedback_outlined,
            label: 'Dar Feedback',
            subtitle: 'Registrar feedback pontual',
            onTap: () => context.go('/feedback/new'),
          ),
          if (isManager) ...[
            _QuickAction(
              icon: Icons.person_search_outlined,
              label: 'Ver Promoções',
              subtitle: 'Candidatos e solicitações abertas',
              onTap: () => context.go('/promotions'),
            ),
            _QuickAction(
              icon: Icons.diversity_3_outlined,
              label: 'Programa de Cotas DGT',
              subtitle: 'Acompanhar metas de diversidade',
              onTap: () => context.go('/quotas'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      );
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon, color: AppColors.primary),
          title: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          onTap: onTap,
        ),
      );
}