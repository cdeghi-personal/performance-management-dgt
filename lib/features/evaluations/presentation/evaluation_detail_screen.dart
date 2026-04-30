import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EvaluationDetailScreen extends ConsumerWidget {
  final String evaluationId;
  const EvaluationDetailScreen({super.key, required this.evaluationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Avaliação')),
      body: Center(child: Text('Avaliação #$evaluationId')),
    );
  }
}