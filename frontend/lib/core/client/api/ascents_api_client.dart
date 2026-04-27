import 'package:cims/core/entity/ascent.dart';

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
  });

  // Aquest mètode recupera les ascensions de l’usuari autenticat
  // associades a un cim concret.
  // Es farà servir, per exemple, per mostrar l’última ascensió al detall del cim.
  Future<List<Ascent>> getAscentsByPeak(int peakId);
}