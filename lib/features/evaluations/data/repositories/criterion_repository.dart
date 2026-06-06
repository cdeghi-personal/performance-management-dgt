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

  /// Busca critérios ativos filtrados pelos IDs do ciclo ativo,
  /// separados por tipo (behavioral / technical).
  Future<Map<CriterionType, List<Criterion>>> getByCycle(
    List<String> criteriaIds,
  ) async {
    if (criteriaIds.isEmpty) {
      return {CriterionType.behavioral: [], CriterionType.technical: []};
    }

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

    return {
      CriterionType.behavioral:
          response.items.where((c) => c.type == CriterionType.behavioral).toList(),
      CriterionType.technical:
          response.items.where((c) => c.type == CriterionType.technical).toList(),
    };
  }
}
