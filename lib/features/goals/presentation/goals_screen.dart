import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_utils.dart' as du;
import '../../../shared/widgets/empty_state.dart';
import '../domain/goal_model.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/goals/new'),
          ),
        ],
      ),
      body: const Center(
        child: AppEmptyState(
          icon: Icons.flag_outlined,
          title: 'Nenhuma meta encontrada',
          subtitle: 'Crie sua primeira meta para o ciclo atual.',
        ),
      ),
    );
  }
}

class GoalStatusBadge extends StatelessWidget {
  final GoalStatus status;
  const GoalStatusBadge({super.key, required this.status});

  static const _labels = {
    GoalStatus.draft: 'Rascunho',
    GoalStatus.active: 'Ativa',
    GoalStatus.atRisk: 'Em Risco',
    GoalStatus.behind: 'Atrasada',
    GoalStatus.completed: 'Concluída',
    GoalStatus.cancelled: 'Cancelada',
  };

  static const _colors = {
    GoalStatus.draft: AppColors.statusDraft,
    GoalStatus.active: AppColors.statusOnTrack,
    GoalStatus.atRisk: AppColors.statusAtRisk,
    GoalStatus.behind: AppColors.statusBehind,
    GoalStatus.completed: AppColors.statusCompleted,
    GoalStatus.cancelled: AppColors.statusDraft,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? AppColors.statusDraft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _labels[status] ?? '',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}