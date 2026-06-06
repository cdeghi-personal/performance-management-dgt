import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/empty_state.dart';
import '../domain/feedback_model.dart';
import '../../../core/theme/app_colors.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedbacks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/feedback/new'),
          ),
        ],
      ),
      body: const Center(
        child: AppEmptyState(
          icon: Icons.forum_outlined,
          title: 'Nenhum feedback registrado',
          subtitle: 'Feedbacks pontuais aparecem aqui em ordem cronológica.',
        ),
      ),
    );
  }
}

class FeedbackTypeBadge extends StatelessWidget {
  final FeedbackType type;
  const FeedbackTypeBadge({super.key, required this.type});

  static const _labels = {
    FeedbackType.positive: 'Positivo',
    FeedbackType.developmental: 'Desenvolvimento',
    FeedbackType.recognition: 'Reconhecimento',
  };

  static const _colors = {
    FeedbackType.positive: AppColors.statusOnTrack,
    FeedbackType.developmental: AppColors.statusCompleted,
    FeedbackType.recognition: AppColors.primary,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[type] ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _labels[type] ?? '',
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}