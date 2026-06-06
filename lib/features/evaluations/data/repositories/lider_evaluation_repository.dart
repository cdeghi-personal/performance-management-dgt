import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/sydle_client.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/api/sydle_search_response.dart';
import '../models/lider_evaluation_model.dart';

final liderEvaluationRepositoryProvider = Provider<LiderEvaluationRepository>(
  (ref) => LiderEvaluationRepository(ref.read(sydleClientProvider)),
);

class LiderEvaluationRepository {
  final SydleClient _client;
  LiderEvaluationRepository(this._client);

  /// Histórico completo das avaliações feitas pelo gestor (como avaliador).
  Future<List<LiderEvaluation>> getByAppraiser(String appraiserId) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.search,
      body: {
        'query': {'term': {'appraiser._id': appraiserId}},
        'sort': [{'_creationDate': {'order': 'asc'}}],
        'size': 20,
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(data, LiderEvaluation.fromJson).items;
  }

  /// Avaliações pendentes do gestor no ciclo ativo (time direto).
  Future<List<LiderEvaluation>> getPendingByAppraiser({
    required String appraiserId,
    required String cycleId,
  }) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.search,
      body: {
        'query': {
          'bool': {
            'must': [
              {'term': {'appraiser._id': appraiserId}},
              {'term': {'cycle._id': cycleId}},
              {'terms': {'status.keyword': ['notStarted', 'onGoing']}},
            ],
          },
        },
        'sort': [{'_creationDate': {'order': 'desc'}}],
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(data, LiderEvaluation.fromJson).items;
  }

  /// Busca a avaliação do gestor onde o colaborador é o EMPLOYEE (para jornada do ciclo).
  Future<LiderEvaluation?> getByEmployeeAndCycle({
    required String employeeId,
    required String cycleId,
  }) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
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

    return SydleSearchResponse.fromJson(data, LiderEvaluation.fromJson).firstOrNull;
  }

  /// Busca a avaliação de um colaborador específico feita por um avaliador específico.
  Future<LiderEvaluation?> getByEmployeeAppraisersAndCycle({
    required String employeeId,
    required String appraiserId,
    required String cycleId,
  }) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.search,
      body: {
        'query': {
          'bool': {
            'must': [
              {'term': {'employee._id': employeeId}},
              {'term': {'appraiser._id': appraiserId}},
              {'term': {'cycle._id': cycleId}},
            ],
          },
        },
        'size': 1,
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(data, LiderEvaluation.fromJson).firstOrNull;
  }

  /// Todas as avaliações (qualquer status) onde o colaborador é o AVALIADO.
  Future<List<LiderEvaluation>> getAllByEmployee(String employeeId) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.search,
      body: {
        'query': {'term': {'employee._id': employeeId}},
        'sort': [{'_creationDate': {'order': 'desc'}}],
        'size': 50,
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(data, LiderEvaluation.fromJson).items;
  }

  /// Avaliações finalizadas onde o colaborador é o AVALIADO (visão do colaborador).
  Future<List<LiderEvaluation>> getFinishedByEmployee(String employeeId) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.search,
      body: {
        'query': {
          'bool': {
            'must': [
              {'term': {'employee._id': employeeId}},
              {'terms': {'status.keyword': ['finished', 'cancelled']}},
            ],
          },
        },
        'sort': [{'_creationDate': {'order': 'asc'}}],
        'size': 20,
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(data, LiderEvaluation.fromJson).items;
  }

  /// Todas as avaliações (qualquer status) feitas por um gestor em um ciclo específico.
  Future<List<LiderEvaluation>> getByAppraisersAndCycle({
    required String appraiserId,
    required String cycleId,
  }) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.search,
      body: {
        'query': {
          'bool': {
            'must': [
              {'term': {'appraiser._id': appraiserId}},
              {'term': {'cycle._id': cycleId}},
            ],
          },
        },
        'sort': [{'_creationDate': {'order': 'asc'}}],
        'size': 50,
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(data, LiderEvaluation.fromJson).items;
  }

  /// Busca todas as avaliações do time no ciclo ativo (para EqualizationPage).
  Future<List<LiderEvaluation>> getByCycle(String cycleId) async {
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.search,
      body: {
        'query': {'term': {'cycle._id': cycleId}},
        'sort': [{'_creationDate': {'order': 'desc'}}],
        'size': 100,
      },
    ) as Map<String, dynamic>;

    return SydleSearchResponse.fromJson(data, LiderEvaluation.fromJson).items;
  }

  /// Avaliação mais recente de um colaborador como AVALIADO (qualquer gestor, qualquer ciclo).
  /// Usado pela GoalsScreen para localizar o registro onde persistir nextGoals.
  Future<LiderEvaluation?> getLatestByEmployee(String employeeId) async {
    if (employeeId.isEmpty) return null;
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.search,
      body: {
        'query': {'term': {'employee._id': employeeId}},
        'sort': [{'_creationDate': {'order': 'desc'}}],
        'size': 1,
      },
    ) as Map<String, dynamic>;
    return SydleSearchResponse.fromJson(data, LiderEvaluation.fromJson).firstOrNull;
  }

  /// Busca uma avaliação do gestor pelo ID.
  Future<LiderEvaluation?> getById(String evalId) async {
    if (evalId.isEmpty) return null;
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.search,
      body: {
        'query': {'term': {'_id': evalId}},
        'size': 1,
      },
    ) as Map<String, dynamic>;
    return SydleSearchResponse.fromJson(data, LiderEvaluation.fromJson).firstOrNull;
  }

  /// Salva (update completo) uma avaliação do gestor.
  Future<void> update(LiderEvaluation evaluation) async {
    await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.update,
      body: evaluation.toJson(),
    );
  }

  /// Patch parcial para equalização — não re-envia arrays embedded pesados.
  Future<void> patchEqualization({
    required String evaluationId,
    EvaluationClassification? classification,
    bool? topPerformer,
    String? commentsPerfMeeting,
  }) async {
    await _client.call(
      SydlePackage.perfMngt,
      SydleClass.liderEvaluation,
      SydleMethod.patch,
      body: {
        '_id': evaluationId,
        if (classification != null) 'classification': classification.sydleValue,
        if (topPerformer != null) 'topPerformer': topPerformer,
        if (commentsPerfMeeting != null && commentsPerfMeeting.isNotEmpty)
          'commentsPerfMeeting': commentsPerfMeeting,
      },
    );
  }
}
