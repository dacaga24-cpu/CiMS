// Aquesta entitat representa una foto ja pujada temporalment a l’emmagatzematge.
// Guarda la ruta que després s’enviarà al backend quan es registri l’ascensió.
class AscentUploadPhoto {
  const AscentUploadPhoto({
    required this.storagePath,
    this.isPrimary = false,
    this.isVerificationEvidence = false,
  });

  // Aquestes dades indiquen on s’ha guardat la imatge i quin paper tindrà dins de l’ascensió.
  // Permeten marcar-la com a principal o com a evidència d’una verificació.
  final String storagePath;
  final bool isPrimary;
  final bool isVerificationEvidence;

  // Converteix la foto pujada al format que espera el backend.
  // Aquesta informació s’envia quan es crea o s’actualitza una ascensió amb imatges.
  Map<String, dynamic> toJson() {
    return {
      'storagePath': storagePath,
      'isPrimary': isPrimary,
      'isVerificationEvidence': isVerificationEvidence,
    };
  }
}

// Aquesta entitat representa la resposta del backend per poder pujar una imatge.
// Inclou la URL temporal, la ruta final i els headers necessaris per completar la pujada.
class AscentSignedUploadUrl {
  const AscentSignedUploadUrl({
    required this.uploadUrl,
    required this.storagePath,
    required this.expiresAt,
    required this.requiredHeaders,
  });

  // Aquestes dades permeten fer la pujada directa de la imatge.
  // Després, storagePath s’utilitza per vincular la foto amb l’ascensió.
  final String uploadUrl;
  final String storagePath;
  final DateTime expiresAt;
  final Map<String, String> requiredHeaders;

  // Aquest constructor adapta la resposta del backend al model de l’aplicació.
  // També normalitza els headers perquè es puguin enviar correctament durant la pujada.
  factory AscentSignedUploadUrl.fromJson(Map<String, dynamic> json) {
    final headers = <String, String>{};
    final rawHeaders = json['requiredHeaders'];
    if (rawHeaders is Map) {
      rawHeaders.forEach((key, value) {
        if (key != null && value != null) {
          headers[key.toString()] = value.toString();
        }
      });
    }

    return AscentSignedUploadUrl(
      uploadUrl: json['uploadUrl'].toString(),
      storagePath: json['storagePath'].toString(),
      expiresAt: DateTime.parse(json['expiresAt'].toString()),
      requiredHeaders: headers,
    );
  }
}