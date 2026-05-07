import 'package:cims/core/entity/peak.dart';

// Aquesta entitat representa una pàgina del catàleg de cims.
// Permet separar els cims carregats de la informació de paginació retornada pel backend.
class PeaksPage {
  const PeaksPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasMore,
  });

  // Cims inclosos dins de la pàgina actual.
  final List<Peak> items;

  // Informació de paginació necessària per carregar més resultats.
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasMore;

  // Aquest constructor transforma la resposta paginada del backend en una entitat del frontend.
  // El backend retorna els cims dins d’items i les dades de paginació dins de pagination.
  factory PeaksPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawPagination = json['pagination'];

    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => Peak.fromJson(Map<String, dynamic>.from(item)))
            .toList()
        : <Peak>[];

    final pagination = rawPagination is Map
        ? Map<String, dynamic>.from(rawPagination)
        : <String, dynamic>{};

    return PeaksPage(
      items: items,
      page: _readInt(pagination['page'], fallback: 1),
      pageSize: _readInt(pagination['pageSize'], fallback: items.length),
      totalItems: _readInt(pagination['totalItems'], fallback: items.length),
      totalPages: _readInt(pagination['totalPages'], fallback: 1),
      hasMore: pagination['hasMore'] == true,
    );
  }

  // Aquest suport evita errors si algun valor numèric arriba amb un format inesperat.
  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
