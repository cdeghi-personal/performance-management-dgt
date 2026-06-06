import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/auth/domain/auth_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isManager = ref.watch(isManagerProvider);
    final location = GoRouterState.of(context).matchedLocation;

    final tabs = _buildTabs(isManager);
    final currentIndex = _indexFor(location, tabs);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(tabs[i].path),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.midGray,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 8,
        items: tabs
            .map((t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }

  static List<_Tab> _buildTabs(bool isManager) => [
        const _Tab(icon: Icons.grid_view_rounded, label: 'Home', path: '/dashboard'),
        const _Tab(icon: Icons.checklist_rounded, label: 'Avaliações', path: '/avaliacoes'),
        const _Tab(icon: Icons.track_changes_rounded, label: 'Metas', path: '/metas'),
        if (isManager)
          const _Tab(icon: Icons.balance_rounded, label: 'Equalização', path: '/avaliacoes/equalizacao'),
        const _Tab(icon: Icons.person_outline_rounded, label: 'Perfil', path: '/perfil'),
      ];

  static int _indexFor(String location, List<_Tab> tabs) {
    // Use longest matching prefix to avoid '/avaliacoes' shadowing '/avaliacoes/equalizacao'.
    var bestIndex = 0;
    var bestLen   = 0;
    for (var i = 0; i < tabs.length; i++) {
      final p = tabs[i].path;
      if (location.startsWith(p) && p.length > bestLen) {
        bestIndex = i;
        bestLen   = p.length;
      }
    }
    return bestIndex;
  }
}

class _Tab {
  final IconData icon;
  final String label;
  final String path;
  const _Tab({required this.icon, required this.label, required this.path});
}
