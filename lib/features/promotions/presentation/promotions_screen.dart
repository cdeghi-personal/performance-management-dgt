import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/promotion_model.dart';
import '../../../core/theme/app_colors.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedbacks de Promoção')),
      body: const Center(
        child: AppEmptyState(
          icon: Icons.person_search_outlined,
          title: 'Nenhuma solicitação aberta',
          subtitle: 'Candidatos a promoção e seus feedbacks aparecem aqui.',
        ),
      ),
    );
  }
}

class PromotionStatusBadge extends StatelessWidget {
  final PromotionStatus status;
  const PromotionStatusBadge({super.key, required this.status});

  static const _labels = {
    PromotionStatus.pending: 'Pendente',
    PromotionStatus.underReview: 'Em análise',
    PromotionStatus.approved: 'Aprovado',
    PromotionStatus.rejected: 'Não aprovado',
    PromotionStatus.onHold: 'Em espera',
  };

  static const _colors = {
    PromotionStatus.pending: AppColors.statusAtRisk,
    PromotionStatus.underReview: AppColors.statusCompleted,
    PromotionStatus.approved: AppColors.statusOnTrack,
    PromotionStatus.rejected: AppColors.statusBehind,
    PromotionStatus.onHold: AppColors.statusDraft,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _labels[status] ?? '',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}