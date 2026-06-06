import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/evaluations/data/models/auto_evaluation_model.dart';

/// Banner exibido no topo das telas de avaliação quando o registro está finalizado ou cancelado.
class ReadOnlyBanner extends StatelessWidget {
  final EvaluationStatus status;
  const ReadOnlyBanner({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isCancelled = status == EvaluationStatus.cancelled;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isCancelled
          ? AppColors.lightGray.withValues(alpha: 0.4)
          : AppColors.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          Icon(
            isCancelled ? Icons.cancel_outlined : Icons.lock_outline,
            size: 16,
            color: isCancelled ? AppColors.midGray : AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isCancelled
                ? 'Esta avaliação foi cancelada'
                : 'Avaliação finalizada — somente leitura',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isCancelled ? AppColors.midGray : AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}
