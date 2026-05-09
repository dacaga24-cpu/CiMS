import 'package:cims/core/entity/ascent.dart';
import 'package:cims/core/entity/ascent_upload_photo.dart';
import 'package:cims/core/entity/ascent_photo.dart';
import 'package:cims/core/entity/ascent_photo_gallery.dart';

// Aquest contracte defineix les operacions de l’API relacionades amb les ascensions.
// Permet registrar, editar, consultar i gestionar fotos d’ascensions sense que
// la resta del projecte conegui com es construeixen les peticions HTTP reals.
abstract class AscentsApiClient {
  // Aquest mètode envia al backend les dades necessàries per registrar una ascensió.
  // La data és opcional perquè un usuari pot completar un cim encara que no recordi
  // el dia exacte de l’ascensió.
  // El backend associa l’ascensió a l’usuari autenticat a partir del token de sessió.
  Future<Ascent> createAscent({
    required int peakId,
    DateTime? ascentDate,
    String? notes,
    List<AscentUploadPhoto> photos = const [],
  });

  // Aquest mètode actualitza una ascensió existent.
  // Permet modificar la data i les notes, i també deixar la data buida
  // quan l’usuari no vol conservar cap dia concret.
  Future<Ascent> updateAscent({
    required int ascentId,
    required DateTime? ascentDate,
    String? notes,
  });

  // Aquest mètode demana al backend una URL temporal per pujar una foto d’ascensió.
  Future<AscentSignedUploadUrl> createAscentPhotoSignedUploadUrl({
    required String mimeType,
    bool isPrimary = false,
  });

  // Aquest mètode recupera totes les fotos associades a una ascensió concreta.
  Future<List<AscentPhoto>> getAscentPhotos(int ascentId);

  // Aquest mètode puja el contingut binari de la imatge a la URL temporal
  // retornada pel backend. Els headers els decideix el backend en signar la
  // URL i s'han d'enviar tal qual al PUT, perquè formen part de la signatura.
  Future<void> uploadAscentPhotoBytes({
    required String uploadUrl,
    required List<int> bytes,
    required Map<String, String> headers,
  });

  // Aquest mètode recupera les ascensions de l’usuari autenticat
  // associades a un cim concret.
  // Es farà servir, per exemple, per mostrar l’última ascensió al detall del cim.
  Future<List<Ascent>> getAscentsByPeak(int peakId);

  // Aquest mètode recupera una pàgina de la galeria de fotos de l'usuari autenticat.
  // S'utilitza per carregar totes les imatges de manera progressiva.
  Future<AscentPhotoGalleryPage> getUserPhotoGallery({
    int limit = 30,
    int offset = 0,
  });
}