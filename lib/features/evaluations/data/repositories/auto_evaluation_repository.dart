import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/sydle_client.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/api/sydle_search_response.dart';
import '../models/auto_evaluation_model.dart';

final autoEvaluationRepositoryProvider = Provider<AutoEvaluationRepository>(
  (ref) => AutoEvaluationRepository(ref.read(sydleClientProvider)),
);

class AutoEvaluationRepository {
  final SydleClient _client;
  AutoEvaluationRepository(this._client);

  /// Histórico completo das auto-avaliações do colaborador (todos os ciclos).
  Future<List<AutoEvaluation>> getByEmployee(String employeeId) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.autoEvaluation,
      SydleMethod.search,
      body: {
        'query': {'term': {'employee._id': employeeId}},
        'sort': [{'_creationDate': {'order': 'desc'}}],
        'size': 20,
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(data, AutoEvaluation.fromJson).items;
  }

  /// Auto-avaliações pendentes do colaborador no ciclo ativo.
  Future<List<AutoEvaluation>> getPendingByEmployee({
    required String employeeId,
    required String cycleId,
  }) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.autoEvaluation,
      SydleMethod.search,
      body: {
        'query': {
          'bool': {
            'must': [
              {'term': {'employee._id': employeeId}},
              {'term': {'cycle._id': cycleId}},
              {'terms': {'status.keyword': ['notStarted', 'onGoing']}},
            ],
          },
        },
        'sort': [{'_creationDate': {'order': 'desc'}}],
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(data, AutoEvaluation.fromJson).items;
  }

  /// Busca a auto-avaliação de um colaborador em um ciclo específico.
  Future<AutoEvaluation?> getByEmployeeAndCycle({
    required String employeeId,
    required String cycleId,
  }) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.autoEvaluation,
      SydleMethod.search,
      body: {
        'query': {
          'bool': {
            'must': [
              {'term': {'employee._id': employeeId}},
              {'term': {'cycle._id': cycleId}},
            ],
          },
        },
        'size': 1,
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(data, AutoEvaluation.fromJson).firstOrNull;
  }

  /// Busca a auto-avaliação finalizada de um colaborador num ciclo específico.
  /// Prioriza status==finished; cai para qualquer status se não encontrar.
  /// Usa employee._id e cycle._id da LiderEvaluation (não o ciclo ativo global).
  Future<AutoEvaluation?> getByEmployeeAndCycleFinished({
    required String employeeId,
    required String cycleId,
  }) async {
    // 1ª tentativa: apenas auto-avaliações finalizadas
    final finishedData = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.autoEvaluation,
      SydleMethod.search,
      body: {
        'query': {
          'bool': {
            'must': [
              {'term': {'employee._id': employeeId}},
              {'term': {'cycle._id': cycleId}},
              {'terms': {'status.keyword': ['finished']}},
            ],
          },
        },
        'size': 1,
      },
    ) as Map<String, dynamic>;

    final finished =
        SydleSearchResponse.fromJson(finishedData, AutoEvaluation.fromJson).firstOrNull;
    if (finished != null) return finished;

    // 2ª tentativa: qualquer status (para diagnóstico — auto-avaliação pode estar onGoing)
    final anyData = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.autoEvaluation,
      SydleMethod.search,
      body: {
        'query': {
          'bool': {
            'must': [
              {'term': {'employee._id': employeeId}},
              {'term': {'cycle._id': cycleId}},
            ],
          },
        },
        'size': 1,
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(anyData, AutoEvaluation.fromJson).firstOrNull;
  }

  /// Busca uma auto-avaliação pelo ID.
  Future<AutoEvaluation?> getById(String evalId) async {
    if (evalId.isEmpty) return null;
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.autoEvaluation,
      SydleMethod.search,
      body: {
        'query': {'term': {'_id': evalId}},
        'size': 1,
      },
    ) as Map<String, dynamic>;
    return SydleSearchResponse.fromJson(data, AutoEvaluation.fromJson).firstOrNull;
  }

  /// Salva (update completo) uma auto-avaliação.
  Future<void> update(AutoEvaluation evaluation) async {
    await _client.call(
      SydlePackage.perfMngt,
      SydleClass.autoEvaluation,
      SydleMethod.update,
      body: evaluation.toJson(),
    );
  }
}
