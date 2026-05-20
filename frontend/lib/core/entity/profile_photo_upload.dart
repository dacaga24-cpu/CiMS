// lib/core/entity/profile_photo_upload.dart

// Aquesta entitat representa la resposta del backend per poder pujar
// una foto de perfil directament a l’emmagatzematge extern.
class ProfilePhotoSignedUploadUrl {
  const ProfilePhotoSignedUploadUrl({
    required this.uploadUrl,
    required this.storagePath,
    required this.expiresAt,
    required this.requiredHeaders,
  });

  final String uploadUrl;
  final String storagePath;
  final DateTime expiresAt;
  final Map<String, String> requiredHeaders;

  // Aquest constructor transforma la resposta del backend en una entitat usable.
  // Inclou els headers obligatoris perquè la pujada a GCS coincideixi amb la signatura.
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
