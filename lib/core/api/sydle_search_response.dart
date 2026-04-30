/// Wrapper para respostas do método _search (padrão Elasticsearch do SYDLE).
///
/// Estrutura esperada:
/// {
///   "hits": {
///     "total": 1,
///     "hits": [{ "_source": { ... } }]
///   }
/// }
class SydleSearchResponse<T> {
  final int total;
  final List<T> items;

  const SydleSearchResponse({required this.total, required this.items});

  factory SydleSearchResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromSource,
  ) {
    final hits = json['hits'] as Map<String, dynamic>? ?? {};
    final hitsList = hits['hits'] as List<dynamic>? ?? [];
    final total = hits['total'];
    final totalCount = total is Map ? (total['value'] as int? ?? 0) : (total as int? ?? 0);

    return SydleSearchResponse(
      total: totalCount,
      items: hitsList
          .map((h) => fromSource(h['_source'] as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEmpty => items.isEmpty;
  T? get firstOrNull => items.isEmpty ? null : items.first;
}

/// Helper: monta query Elasticsearch simples de match.
Map<String, dynamic> matchQuery(String field, dynamic value, {int size = 50}) => {
  'query': {
    'bool': {
      'must': [
        {'match': {field: value}},
      ],
    },
  },
  'size': size,
};

/// Helper: monta query para buscar por _id.
Map<String, dynamic> termQuery(String field, dynamic value, {int size = 50}) => {
  'query': {
    'term': {field: value},
  },
  'size': size,
};

/// Helper: busca todos os registros (sem filtro).
Map<String, dynamic> matchAllQuery({int size = 100}) => {
  'query': {'match_all': {}},
  'size': size,
};