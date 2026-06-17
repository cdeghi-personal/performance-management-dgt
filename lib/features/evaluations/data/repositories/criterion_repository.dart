import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/sydle_client.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/api/sydle_search_response.dart';
import '../models/criterion_model.dart';

final criterionRepositoryProvider = Provider<CriterionRepository>(
  (ref) => CriterionRepository(ref.read(sydleClientProvider)),
);

class CriterionRepository {
  final SydleClient _client;
  CriterionRepository(this._client);

  /// Busca critérios ativos filtrados pelos IDs do ciclo ativo.
  /// Retorna mapa indexado por CriterionType (suporta todos os 5 tipos).
  Future<Map<CriterionType, List<Criterion>>> getByCycle(
    List<String> criteriaIds,
  ) async {
    final empty = {for (final t in CriterionType.values) t: <Criterion>[]};
    if (criteriaIds.isEmpty) return empty;

    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.criterion,
      SydleMethod.search,
      body: {
        'query': {
          'bool': {
            'must': [
              {'term': {'active': true}},
              {'ids': {'values': criteriaIds}},
            ],
          },
        },
        'size': criteriaIds.length + 10,
      },
    ) as Map<String, dynamic>;

    final response = SydleSearchResponse.fromJson(data, Criterion.fromJson);

    final result = {for (final t in CriterionType.values) t: <Criterion>[]};
    for (final c in response.items) {
      result[c.type]!.add(c);
    }
    return result;
  }
}
