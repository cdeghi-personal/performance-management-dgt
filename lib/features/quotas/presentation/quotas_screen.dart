import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/quota_model.dart';
import '../../../core/theme/app_colors.dart';

class QuotasScreen extends ConsumerWidget {
  const QuotasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programa de Cotas DGT')),
      body: const Center(
        child: AppEmptyState(
          icon: Icons.diversity_3_outlined,
          title: 'Dados não disponíveis',
          subtitle: 'Aguardando integração com SYDLE ONE.',
        ),
      ),
    );
  }
}

class QuotaProgressCard extends StatelessWidget {
  final QuotaTarget target;
  const QuotaProgressCard({super.key, required this.target});

  Color get _color {
    if (target.isMet) return AppColors.statusOnTrack;
    if (target.fillRate >= 0.7) return AppColors.statusAtRisk;
    return AppColors.statusBehind;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    target.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${target.currentCount}/${target.targetCount}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearPercentIndicator(
              percent: target.fillRate.clamp(0.0, 1.0),
              lineHeight: 8,
              backgroundColor: AppColors.border,
              progressColor: _color,
              barRadius: const Radius.circular(4),
              padding: EdgeInsets.zero,
            ),
            if (target.gap > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Faltam ${target.gap} vaga(s)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}