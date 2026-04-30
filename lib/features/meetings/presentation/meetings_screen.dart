import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/empty_state.dart';

class MeetingsScreen extends ConsumerWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reuniões Executivas')),
      body: const Center(
        child: AppEmptyState(
          icon: Icons.groups_outlined,
          title: 'Nenhuma reunião agendada',
          subtitle: 'Reuniões do grupo executivo sobre performance aparecerão aqui.',
        ),
      ),
    );
  }
}