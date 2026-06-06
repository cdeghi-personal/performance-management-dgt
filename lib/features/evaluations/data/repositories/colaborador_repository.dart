import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_constants.dart';
import '../../../../core/api/sydle_client.dart';
import '../../../../core/api/sydle_search_response.dart';

final colaboradorRepositoryProvider = Provider<ColaboradorRepository>(
  (ref) => ColaboradorRepository(ref.read(sydleClientProvider)),
);

// ── Modelo público ─────────────────────────────────────────────────────────────

class ColaboradorDGT {
  final String id;
  final String name;
  // TODO: confirmar campo exato de nível de carreira no SYDLE colaboradorDGT
  // Tentativas em ordem: careerLevel, nivelCarreira, nivel, cargo, senioridade
  final String careerLevel;

  const ColaboradorDGT({
    required this.id,
    required this.name,
    required this.careerLevel,
  });

  factory ColaboradorDGT.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as String? ?? '';
    String name = '';
    for (final key in ['name', 'nomeCompleto', 'nome', 'displayName', 'fullName']) {
      final v = json[key];
      if (v is String && v.isNotEmpty) { name = v; break; }
    }
    String level = '';
    for (final key in ['careerLevel', 'nivelCarreira', 'nivel', 'cargo', 'senioridade']) {
      final v = json[key];
      if (v is String && v.isNotEmpty) { level = v; break; }
    }
    return ColaboradorDGT(
      id: id,
      name: name.isNotEmpty ? name : 'Nome não encontrado',
      careerLevel: level,
    );
  }
}

// ── Repositório ────────────────────────────────────────────────────────────────

class ColaboradorRepository {
  final SydleClient _client;
  ColaboradorRepository(this._client);

  /// Busca nomes de colaboradores por IDs — retorna mapa {id: nome}.
  Future<Map<String, String>> getNamesByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final data = await _client.call(
      SydlePackage.projetosDGT,
      SydleClass.colaboradorDGT,
      SydleMethod.search,
      body: {
        'query': {'terms': {'_id': ids}},
        'size': ids.length,
      },
    ) as Map<String, dynamic>;
    final items =
        SydleSearchResponse.fromJson(data, ColaboradorDGT.fromJson).items;
    return {for (final c in items) c.id: c.name};
  }

  /// Busca todos os colaboradores DGT — usado pelo GoalsScreen (HR).
  Future<List<ColaboradorDGT>> getAll({int size = 200}) async {
    final data = await _client.call(
      SydlePackage.projetosDGT,
      SydleClass.colaboradorDGT,
      SydleMethod.search,
      body: {'query': {'match_all': {}}, 'size': size},
    ) as Map<String, dynamic>;
    return SydleSearchResponse.fromJson(data, ColaboradorDGT.fromJson).items;
  }

  /// Busca dados completos de colaboradores por IDs — retorna mapa {id: ColaboradorDGT}.
  /// Inclui nível de carreira e demais campos disponíveis.
  Future<Map<String, ColaboradorDGT>> getDetailsByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final data = await _client.call(
      SydlePackage.projetosDGT,
      SydleClass.colaboradorDGT,
      SydleMethod.search,
      body: {
        'query': {'terms': {'_id': ids}},
        'size': ids.length,
      },
    ) as Map<String, dynamic>;
    final items =
        SydleSearchResponse.fromJson(data, ColaboradorDGT.fromJson).items;
    return {for (final c in items) c.id: c};
  }
}
