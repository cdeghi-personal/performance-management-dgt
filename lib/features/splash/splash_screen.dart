import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../auth/domain/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;
  late final Animation<double> _needle;

  @override
  void initState() {
    super.initState();

    // Total da animação: 3000ms + 1500ms pause = 4500ms na splash
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    // Elementos surgem nos primeiros 400ms
    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.13, curve: Curves.easeOut),
      ),
    );

    // Ponteiro varre de 0 a 0.82 (82% = zona de alta performance)
    _needle = Tween<double>(begin: 0.0, end: 0.82).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.10, 0.90, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward().then((_) async {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (!mounted) return;
      final isAuth =
          ref.read(authStateProvider).valueOrNull?.isAuthenticated ?? false;
      context.go(isAuth ? '/dashboard' : '/login');
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGray,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo DGT
            FadeTransition(
              opacity: _fadeIn,
              child: Image.asset(
                'assets/icons/Icone_DGT_Performance_Management_2.png',
                height: 100,
              ),
            ),
            const SizedBox(height: 36),
            // Conta-giros — painter escuta _needle diretamente via repaint
            FadeTransition(
              opacity: _fadeIn,
              child: SizedBox(
                width: 280,
                height: 148,
                child: CustomPaint(
                  painter: _TachometerPainter(_needle),
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Label
            FadeTransition(
              opacity: _fadeIn,
              child: const Text(
                'Performance Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tachometer painter ────────────────────────────────────────────────────────

class _TachometerPainter extends CustomPainter {
  // Recebe a Animation e passa como repaint listener — garante redesenho a
  // cada frame sem depender do widget tree reconstruir o CustomPaint.
  _TachometerPainter(this._animation) : super(repaint: _animation);

  final Animation<double> _animation;
  double get _value => _animation.value;

  // Semicircle: começa em π (esquerda/9h), varre π rad no sentido horário
  // passando por 3π/2 (cima/12h) até 2π (direita/3h).
  // Com center no fundo do widget, o arco aparece na metade superior.
  static const _startAngle = math.pi;
  static const _sweepAngle = math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height;
    final center = Offset(cx, cy);
    final r = cx - 16.0;
    final rect = Rect.fromCircle(center: center, radius: r);

    // ── Faixas de zona coloridas ─────────────────────────────────────────────

    _arc(canvas, rect, _startAngle, _sweepAngle * 0.42,
        const Color(0xFF4CAF50), 0.28, 14);
    _arc(canvas, rect, _startAngle + _sweepAngle * 0.42, _sweepAngle * 0.28,
        const Color(0xFFFCB017), 0.28, 14);
    _arc(canvas, rect, _startAngle + _sweepAngle * 0.70, _sweepAngle * 0.30,
        const Color(0xFFFF5722), 0.38, 14);

    // ── Contorno do arco ─────────────────────────────────────────────────────

    canvas.drawArc(
      rect, _startAngle, _sweepAngle, false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // ── Marcações (ticks) ────────────────────────────────────────────────────

    const ticks = 20;
    for (int i = 0; i <= ticks; i++) {
      final t = i / ticks;
      final angle = _startAngle + _sweepAngle * t;
      final major = i % 4 == 0;
      final len = major ? 14.0 : 7.0;

      final Color color;
      final double alpha;
      if (t <= 0.42) {
        color = const Color(0xFF66BB6A);
        alpha = 0.80;
      } else if (t <= 0.70) {
        color = const Color(0xFFFCB017);
        alpha = 0.80;
      } else {
        color = const Color(0xFFFF7043);
        alpha = 0.90;
      }

      canvas.drawLine(
        Offset(cx + (r - len) * math.cos(angle), cy + (r - len) * math.sin(angle)),
        Offset(cx + r * math.cos(angle),          cy + r * math.sin(angle)),
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..strokeWidth = major ? 1.5 : 1.0
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Ponteiro ─────────────────────────────────────────────────────────────

    if (_value > 0.005) {
      final angle = _startAngle + _sweepAngle * _value;
      final tip = Offset(
        cx + (r - 20) * math.cos(angle),
        cy + (r - 20) * math.sin(angle),
      );

      // Glow atrás do ponteiro
      canvas.drawLine(center, tip,
          Paint()
            ..color = const Color(0xFFFCB017).withValues(alpha: 0.20)
            ..strokeWidth = 10
            ..strokeCap = StrokeCap.round);

      // Ponteiro
      canvas.drawLine(center, tip,
          Paint()
            ..color = const Color(0xFFFCB017)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
    }

    // ── Hub central ──────────────────────────────────────────────────────────

    canvas.drawCircle(center, 9.0, Paint()..color = const Color(0xFFFCB017));
    canvas.drawCircle(center, 9.0,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.30)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.drawCircle(center, 3.5, Paint()..color = AppColors.darkGray);
  }

  void _arc(Canvas canvas, Rect rect, double start, double sweep,
      Color color, double alpha, double width) {
    canvas.drawArc(rect, start, sweep, false,
        Paint()
          ..color = color.withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.butt);
  }

  @override
  bool shouldRepaint(_TachometerPainter old) => old._value != _value;
}
