import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/goals/presentation/goals_screen.dart';
import '../../features/goals/presentation/goal_form_screen.dart';
import '../../features/evaluations/presentation/evaluations_screen.dart';
import '../../features/evaluations/presentation/evaluation_detail_screen.dart';
import '../../features/feedback/presentation/feedback_screen.dart';
import '../../features/feedback/presentation/feedback_form_screen.dart';
import '../../features/meetings/presentation/meetings_screen.dart';
import '../../features/meetings/presentation/meeting_detail_screen.dart';
import '../../features/promotions/presentation/promotions_screen.dart';
import '../../features/quotas/presentation/quotas_screen.dart';
import '../shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull?.isAuthenticated ?? false;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) return '/login';
      if (isAuthenticated && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (ctx, _) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (ctx, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (ctx, _) => const GoalsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (ctx, _) => const GoalFormScreen(),
              ),
              GoRoute(
                path: ':id/edit',
                builder: (ctx, s) => GoalFormScreen(goalId: s.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(
            path: '/evaluations',
            builder: (ctx, _) => const EvaluationsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (ctx, s) => EvaluationDetailScreen(
                  evaluationId: s.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/feedback',
            builder: (ctx, _) => const FeedbackScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (ctx, _) => const FeedbackFormScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/meetings',
            builder: (ctx, _) => const MeetingsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (ctx, s) => MeetingDetailScreen(
                  meetingId: s.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/promotions',
            builder: (ctx, _) => const PromotionsScreen(),
          ),
          GoRoute(
            path: '/quotas',
            builder: (ctx, _) => const QuotasScreen(),
          ),
        ],
      ),
    ],
  );
});