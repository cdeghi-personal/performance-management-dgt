import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/sydle_client.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/api/sydle_search_response.dart';
import '../models/cycle_model.dart';

final cycleRepositoryProvider = Provider<CycleRepository>(
  (ref) => CycleRepository(ref.read(sydleClientProvider)),
);

class CycleRepository {
  final SydleClient _client;
  CycleRepository(this._client);

  /// Busca o ciclo ativo: primeiro OnGoing, depois o Finished mais recente.
  /// Resultado deve ser consumido via activeCycleProvider — nunca buscar individualmente nas features.
  Future<Cycle?> getActiveCycle() async {
    // Passo 1: ciclo em andamento
    final ongoingData = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.cycle,
      SydleMethod.search,
      body: {
        'query': {'term': {'status.keyword': 'OnGoing'}},
        'size': 1,
      },
    ) as Map<String, dynamic>;

    final ongoing = SydleSearchResponse.fromJson(ongoingData, Cycle.fromJson);
    if (ongoing.firstOrNull != null) return ongoing.firstOrNull;

    // Passo 2: nenhum OnGoing — pega o Finished mais recente
    final finishedData = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.cycle,
      SydleMethod.search,
      body: {
        'query': {'term': {'status.keyword': 'Finished'}},
        'sort': [{'_creationDate': {'order': 'desc'}}],
        'size': 1,
      },
    ) as Map<String, dynamic>;

    final finished = SydleSearchResponse.fromJson(finishedData, Cycle.fromJson);
    return finished.firstOrNull;
  }

  /// Atualiza as fases do ciclo via _update com payload completo (tabPhases embedded).
  Future<void> updateCyclePhases({
    required Cycle cycle,
    required List<TabPhase> phases,
  }) async {
    print('[CycleRepo] updateCyclePhases id=${cycle.id}');
    await _client.call(
      SydlePackage.perfMngt,
      SydleClass.cycle,
      SydleMethod.update,
      body: {
        '_id': cycle.id,
        'period': cycle.period,
        'year': cycle.year,
        'status': cycle.status.sydleValue,
        'criteria': cycle.criteriaIds.map((id) => {'_id': id}).toList(),
        if (cycle.cycleDate != null)
          'cycleDate': cycle.cycleDate!.millisecondsSinceEpoch,
        'tabPhases': phases.map((p) => p.toJson()).toList(),
      },
    );
    print('[CycleRepo] updateCyclePhases OK');
  }

  /// Busca múltiplos ciclos por IDs em uma única chamada.
  Future<Map<String, Cycle>> getByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.cycle,
      SydleMethod.search,
      body: {
        'query': {'terms': {'_id': ids}},
        'size': ids.length,
      },
    ) as Map<String, dynamic>;
    final cycles = SydleSearchResponse.fromJson(data, Cycle.fromJson).items;
    return {for (final c in cycles) c.id: c};
  }
}
