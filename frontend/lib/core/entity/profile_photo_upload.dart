// Aquesta entitat representa la resposta del backend per pujar una foto de perfil.
// Inclou la informació necessària per enviar la imatge directament a l’emmagatzematge.
class ProfilePhotoSignedUploadUrl {
  const ProfilePhotoSignedUploadUrl({
    required this.uploadUrl,
    required this.storagePath,
    required this.expiresAt,
    required this.requiredHeaders,
  });

  // Aquestes dades permeten completar la pujada de la foto de perfil.
  // La ruta final s’utilitza després per associar la imatge al compte de l’usuari.
  final String uploadUrl;
  final String storagePath;
  final DateTime expiresAt;
  final Map<String, String> requiredHeaders;

  // Aquest constructor transforma la resposta del backend en una entitat usable.
  // També normalitza els headers perquè es puguin enviar correctament durant la pujada.
  factory ProfilePhotoSignedUploadUrl.fromJson(Map<String, dynamic> json) {
    final headers = <String, String>{};
    final rawHeaders = json['requiredHeaders'];

    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        if (key != null && value != null) {
          headers[key.toString()] = value.toString();
        }
      });
    }

    return ProfilePhotoSignedUploadUrl(
      uploadUrl: json['uploadUrl'].toString(),
      storagePath: json['storagePath'].toString(),
      expiresAt: DateTime.parse(json['expiresAt'].toString()),
      requiredHeaders: headers,
    );
  }
}