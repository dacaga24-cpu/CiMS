// Aquest model representa la resposta paginada de la galeria de fotos.
// Permet carregar les imatges de l'usuari progressivament sense demanar-les totes de cop.
class AscentPhotoGalleryPage {
  const AscentPhotoGalleryPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.hasMore,
    this.nextOffset,
  });

  // Aquestes dades controlen les fotos visibles i la continuació de la paginació.
  // El frontend les utilitza per saber si ha de carregar més resultats.
  final List<AscentPhotoGalleryItem> items;
  final int limit;
  final int offset;
  final bool hasMore;
  final int? nextOffset;

  // Aquest constructor transforma la resposta del backend en una pàgina de galeria.
  // Si algun camp no arriba, aplica valors segurs per evitar errors de càrrega.
  factory AscentPhotoGalleryPage.fromJson(Map<String, dynamic> json) {
    return AscentPhotoGalleryPage(
      items: _asList(json['items'])
          .map((item) => AscentPhotoGalleryItem.fromJson(item))
          .toList(),
      limit: _asInt(json['limit']),
      offset: _asInt(json['offset']),
      hasMore: _asBool(json['hasMore']),
      nextOffset: json['nextOffset'] == null ? null : _asInt(json['nextOffset']),
    );
  }
}

// Aquest model representa una foto dins de la galeria completa.
// Manté la relació amb l'ascensió i el cim per poder donar context a cada imatge.
class AscentPhotoGalleryItem {
  const AscentPhotoGalleryItem({
    required this.id,
    required this.ascentId,
    required this.peakId,
    required this.peakName,
    required this.ascentDate,
    this.storagePath,
    this.downloadUrl,
    this.isPrimary = false,
    this.createdAt,
  });

  // Aquestes dades permeten mostrar la imatge i identificar d'on prové.
  // El downloadUrl és temporal i serveix per visualitzar la foto sense fer públic el bucket.
  final int id;
  final int ascentId;
  final int peakId;
  final String peakName;
  final String ascentDate;
  final String? storagePath;
  final String? downloadUrl;
  final bool isPrimary;
  final String? createdAt;

  // Aquest constructor adapta el JSON de cada foto al format que consumeix la pantalla.
  // Accepta noms en camelCase i snake_case per mantenir compatibilitat amb el backend.
  factory AscentPhotoGalleryItem.fromJson(Map<String, dynamic> json) {
    return AscentPhotoGalleryItem(
      id: _asInt(json['id']),
      ascentId: _asInt(json['ascentId'] ?? json['ascent_id']),
      peakId: _asInt(json['peakId'] ?? json['peak_id']),
      peakName: _asString(json['peakName'] ?? json['peak_name']),
      ascentDate: _asString(json['ascentDate'] ?? json['ascent_date']),
      storagePath:
          _asNullableString(json['storagePath'] ?? json['storage_path']),
      downloadUrl:
          _asNullableString(json['downloadUrl'] ?? json['download_url']),
      isPrimary: _asBool(json['isPrimary'] ?? json['is_primary']),
      createdAt: _asNullableString(json['createdAt'] ?? json['created_at']),
    );
  }
}

// Aquestes funcions converteixen valors del JSON a tipus segurs.
// Eviten que la galeria falli si algun camp arriba buit o amb un format diferent.
int _asInt(dynamic value, {int defaultValue = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

String _asString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  return value.toString();
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return false;
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  return <Map<String, dynamic>>[];
}