import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum CycleStepStatus { done, active, notStarted, future }

class StepStatusBadge extends StatelessWidget {
  final CycleStepStatus status;

  const StepStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    Color bg;

    switch (status) {
      case CycleStepStatus.done:
        label = 'Concluída';
        color = AppColors.statusOnTrack;
        bg = AppColors.statusOnTrackBg;
        break;
      case CycleStepStatus.active:
        label = 'Em andamento';
        color = AppColors.statusAtRisk;
        bg = AppColors.statusAtRiskBg;
        break;
      case CycleStepStatus.notStarted:
        label = 'Não iniciado';
        color = AppColors.statusBehind;
        bg = AppColors.statusBehindBg;
        break;
      case CycleStepStatus.future:
        label = 'Em breve';
        color = AppColors.textDisabled;
        bg = AppColors.statusDraftBg;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }
}

class ClassificationBadge extends StatelessWidget {
  final String classification;

  const ClassificationBadge({super.key, required this.classification});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;

    final lower = classification.toLowerCase();
    if (lower == 'abaixo' || lower == 'abaixo do nível') {
      color = AppColors.statusBehind;
      bg = AppColors.statusBehindBg;
    } else if (lower == 'no nível' || lower == 'no_nivel') {
      color = AppColors.statusCompleted;
      bg = AppColors.statusCompletedBg;
    } else if (lower == 'acima' || lower == 'acima do nível') {
      color = AppColors.statusOnTrack;
      bg = AppColors.statusOnTrackBg;
    } else if (lower == 'top' || lower == 'top performer') {
      color = AppColors.statusAtRisk;
      bg = AppColors.statusAtRiskBg;
    } else {
      color = AppColors.textSecondary;
      bg = AppColors.statusDraftBg;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(classification,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color)),
    );
  }
}
