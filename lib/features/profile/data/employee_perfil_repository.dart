import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/sydle_client.dart';
import '../../../core/api/sydle_search_response.dart';
import 'employee_perfil_model.dart';

final employeePerfilRepositoryProvider = Provider<EmployeePerfilRepository>(
  (ref) => EmployeePerfilRepository(ref.read(sydleClientProvider)),
);

class EmployeePerfilRepository {
  final SydleClient _client;
  EmployeePerfilRepository(this._client);

  Future<EmployeePerfil?> getByEmployeeId(String employeeId) async {
    if (employeeId.isEmpty) return null;
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.employeeProfile,
      SydleMethod.search,
      body: {
        'query': {'term': {'employee._id': employeeId}},
        'size': 1,
      },
    ) as Map<String, dynamic>;
    return SydleSearchResponse.fromJson(data, EmployeePerfil.fromJson).firstOrNull;
  }

  Future<Map<String, EmployeePerfil>> getByEmployeeIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final data = await _client.call(
      SydlePackage.perfMngt,
      SydleClass.employeeProfile,
      SydleMethod.search,
      body: {
        'query': {'terms': {'employee._id': ids}},
        'size': ids.length,
      },
    ) as Map<String, dynamic>;
    final list = SydleSearchResponse.fromJson(data, EmployeePerfil.fromJson).items;
    return {for (final p in list) if (p.employeeId.isNotEmpty) p.employeeId: p};
  }
}
