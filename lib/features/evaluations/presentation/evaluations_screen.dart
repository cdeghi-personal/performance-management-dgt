import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/evaluation_model.dart';
import '../../../core/theme/app_colors.dart';

class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Avaliações'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Minhas Avaliações'),
              Tab(text: 'Do Time'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
          ),
        ),
        body: const TabBarView(
          children: [
            _MyEvaluationsTab(),
            _TeamEvaluationsTab(),
          ],
        ),
      ),
    );
  }
}

class _MyEvaluationsTab extends StatelessWidget {
  const _MyEvaluationsTab();

  @override
  Widget build(BuildContext context) => const Center(
        child: AppEmptyState(
          icon: Icons.assessment_outlined,
          title: 'Nenhuma avaliação aberta',
          subtitle: 'As avaliações semestrais aparecerão aqui.',
        ),
      );
}

class _TeamEvaluationsTab extends StatelessWidget {
  const _TeamEvaluationsTab();

  @override
  Widget build(BuildContext context) => const Center(
        child: AppEmptyState(
          icon: Icons.group_outlined,
          title: 'Avaliações do time',
          subtitle: 'Visível para gestores e diretores.',
        ),
      );
}

class EvaluationScoreBadge extends StatelessWidget {
  final EvaluationScore score;
  const EvaluationScoreBadge({super.key, required this.score});

  static const _labels = {
    EvaluationScore.exceedsExpectations: 'Acima das expectativas',
    EvaluationScore.meetsExpectations: 'Atende',
    EvaluationScore.partiallyMeets: 'Atende parcialmente',
    EvaluationScore.doesNotMeet: 'Não atende',
  };

  static const _colors = {
    EvaluationScore.exceedsExpectations: AppColors.scoreExceeds,
    EvaluationScore.meetsExpectations: AppColors.scoreMeets,
    EvaluationScore.partiallyMeets: AppColors.scoreBelow,
    EvaluationScore.doesNotMeet: AppColors.scoreUnsatisfactory,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[score] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _labels[score] ?? '',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}