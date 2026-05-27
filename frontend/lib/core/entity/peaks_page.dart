import 'package:cims/core/entity/peak.dart';

// Aquesta entitat representa una pàgina del catàleg de cims.
// Separa els cims carregats de la informació necessària per continuar la paginació.
class PeaksPage {
  const PeaksPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
    required this.hasMore,
  });

  // Aquestes dades defineixen el contingut de la pàgina actual.
  final List<Peak> items;

  // Aquestes dades indiquen l’estat de la paginació.
  // Permeten saber quants resultats hi ha i si es poden carregar més pàgines.
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;
  final bool hasMore;

  // Aquest constructor transforma la resposta paginada del backend en una entitat del frontend.
  // Llegeix els cims i la informació de paginació aplicant valors segurs si algun camp no arriba.
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

  // Aquesta funció converteix valors numèrics del JSON a enters.
  // Si el valor no és vàlid, aplica el valor de reserva indicat.
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