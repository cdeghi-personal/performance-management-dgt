import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/evaluations/data/models/cycle_model.dart';

/// Badge dinâmico do ciclo ativo. Nunca usa texto fixo.
class CycleBadge extends StatelessWidget {
  final Cycle cycle;
  const CycleBadge({super.key, required this.cycle});

  @override
  Widget build(BuildContext context) {
    final isActive = cycle.status == CycleStatus.onGoing;
    final label = '${cycle.period} ${cycle.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.lightGray.withValues(alpha: 0.3),
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.lightGray,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive) ...[
            _AnimatedDot(),
            const SizedBox(width: 6),
          ],
          Text(
            isActive ? '$label — em andamento' : '$label — encerrado',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.midGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _anim,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        ),
      );
}

/// Skeleton do badge enquanto o ciclo carrega.
class CycleBadgeSkeleton extends StatelessWidget {
  const CycleBadgeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        width: 180,
        decoration: BoxDecoration(
          color: AppColors.lightGray.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
      );
}
