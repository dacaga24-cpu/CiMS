// Aquesta entitat representa una foto ja pujada temporalment a l’emmagatzematge.
// Guarda la ruta que després s’enviarà al backend quan es registri l’ascensió.
class AscentUploadPhoto {
  const AscentUploadPhoto({
    required this.storagePath,
    this.isPrimary = false,
    this.isVerificationEvidence = false,
  });

  final String storagePath;
  final bool isPrimary;
  final bool isVerificationEvidence;

  Map<String, dynamic> toJson() {
    return {
      'storagePath': storagePath,
      'isPrimary': isPrimary,
      'isVerificationEvidence': isVerificationEvidence,
    };
  }
}

// Aquesta entitat representa la resposta del backend per poder pujar una imatge.
// Inclou la URL temporal de pujada, la ruta definitiva que quedarà associada
// a la foto i els headers obligatoris per fer la pujada a Google Cloud Storage.
class AscentSignedUploadUrl {
  const AscentSignedUploadUrl({
    required this.uploadUrl,
    required this.storagePath,
    required this.expiresAt,
    required this.requiredHeaders,
  });

  final String uploadUrl;
  final String storagePath;
  final DateTime expiresAt;
  final Map<String, String> requiredHeaders;

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