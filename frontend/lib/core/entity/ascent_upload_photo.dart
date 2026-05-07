// Aquesta entitat representa una foto ja pujada temporalment a l’emmagatzematge.
// Guarda la ruta que després s’enviarà al backend quan es registri l’ascensió.
class AscentUploadPhoto {
  const AscentUploadPhoto({
    required this.storagePath,
    this.isPrimary = false,
  });

  final String storagePath;
  final bool isPrimary;

  Map<String, dynamic> toJson() {
    return {
      'storagePath': storagePath,
      'isPrimary': isPrimary,
    };
  }
}

// Aquesta entitat representa la resposta del backend per poder pujar una imatge.
// Inclou la URL temporal de pujada i la ruta definitiva que quedarà associada a la foto.
class AscentSignedUploadUrl {
  const AscentSignedUploadUrl({
    required this.uploadUrl,
    required this.storagePath,
    required this.expiresAt,
  });

  final String uploadUrl;
  final String storagePath;
  final DateTime expiresAt;

  factory AscentSignedUploadUrl.fromJson(Map<String, dynamic> json) {
    return AscentSignedUploadUrl(
      uploadUrl: json['uploadUrl'].toString(),
      storagePath: json['storagePath'].toString(),
      expiresAt: DateTime.parse(json['expiresAt'].toString()),
    );
  }
}
