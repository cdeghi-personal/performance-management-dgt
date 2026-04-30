import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../domain/feedback_model.dart';

class FeedbackFormScreen extends ConsumerStatefulWidget {
  const FeedbackFormScreen({super.key});

  @override
  ConsumerState<FeedbackFormScreen> createState() => _FeedbackFormScreenState();
}

class _FeedbackFormScreenState extends ConsumerState<FeedbackFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  FeedbackType _type = FeedbackType.positive;
  FeedbackVisibility _visibility = FeedbackVisibility.managerOnly;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dar Feedback')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Tipo
            const Text('Tipo de feedback',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            SegmentedButton<FeedbackType>(
              segments: const [
                ButtonSegment(
                  value: FeedbackType.positive,
                  label: Text('Positivo'),
                  icon: Icon(Icons.thumb_up_outlined),
                ),
                ButtonSegment(
                  value: FeedbackType.developmental,
                  label: Text('Dev.'),
                  icon: Icon(Icons.trending_up),
                ),
                ButtonSegment(
                  value: FeedbackType.recognition,
                  label: Text('Reconhec.'),
                  icon: Icon(Icons.star_outlined),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 20),

            // Para quem
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Para (nome do colaborador) *',
                prefixIcon: Icon(Icons.person_search_outlined),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 16),

            // Mensagem
            TextFormField(
              controller: _messageCtrl,
              decoration: const InputDecoration(
                labelText: 'Mensagem *',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (v) =>
                  v == null || v.trim().length < 20 ? 'Mínimo 20 caracteres' : null,
            ),
            const SizedBox(height: 16),

            // Visibilidade
            DropdownButtonFormField<FeedbackVisibility>(
              value: _visibility,
              decoration: const InputDecoration(labelText: 'Visibilidade'),
              items: const [
                DropdownMenuItem(
                  value: FeedbackVisibility.managerOnly,
                  child: Text('Apenas gestor'),
                ),
                DropdownMenuItem(
                  value: FeedbackVisibility.publicVisible,
                  child: Text('Visível para o colaborador'),
                ),
                DropdownMenuItem(
                  value: FeedbackVisibility.private,
                  child: Text('Privado (apenas eu)'),
                ),
              ],
              onChanged: (v) => setState(() => _visibility = v!),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // TODO: integrar com SYDLE API
                }
              },
              child: const Text('Enviar Feedback'),
            ),
          ],
        ),
      ),
    );
  }
}