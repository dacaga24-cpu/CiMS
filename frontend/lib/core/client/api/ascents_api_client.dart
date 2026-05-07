import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';

// Aquest contracte defineix les operacions de l’API relacionades amb les ascensions.
// Permet registrar i consultar ascensions sense que la resta del projecte conegui
// com es construeixen les peticions HTTP reals.
abstract class AscentsApiClient {
  // Aquest mètode envia al backend les dades necessàries per registrar una ascensió.
  // El backend associa l’ascensió a l’usuari autenticat a partir del token de sessió.
  Future<Ascent> createAscent({
    required int peakId,
    required DateTime ascentDate,
    String? notes,
    List<AscentUploadPhoto> photos = const [],
  });

  // Aquest mètode demana al backend una URL temporal per pujar una foto d’ascensió.
  Future<AscentSignedUploadUrl> createAscentPhotoSignedUploadUrl({
    required String mimeType,
    bool isPrimary = false,
  });

  // Aquest mètode puja el contingut binari de la imatge a la URL temporal
  // retornada pel backend. Els headers els decideix el backend en signar la
  // URL (Content-Type i, si escau, extensionHeaders com x-goog-content-length-range)
  // i s'han d'enviar tal qual al PUT, perquè formen part de la signatura.
  Future<void> uploadAscentPhotoBytes({
    required String uploadUrl,
    required List<int> bytes,
    required Map<String, String> headers,
  });

  // Aquest mètode recupera les ascensions de l’usuari autenticat
  // associades a un cim concret.
  // Es farà servir, per exemple, per mostrar l’última ascensió al detall del cim.
  Future<List<Ascent>> getAscentsByPeak(int peakId);
}
