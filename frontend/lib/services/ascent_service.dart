// ascent_service.dart
// Responsabilidad: Llamadas HTTP a los endpoints de ascensiones.
// NO contiene lógica de negocio ni gestión de estado.

// import 'package:http/http.dart' as http;
// import '../core/constants/api_constants.dart';
// import '../models/ascent.dart';

class AscentService {
  // POST /api/ascents — Registra una nueva ascensión
  // Envía: { peakId, ascentDate, notes } + token en header
  // Devuelve: datos de la ascensión creada
  Future<Map<String, dynamic>> create({
    required int peakId,
    required String ascentDate,
    String? notes,
    required String token,
  }) async {
    throw UnimplementedError();
  }

  // PUT /api/ascents/:id — Actualiza una ascensión
  // Envía: { ascentDate, notes } + token en header
  Future<Map<String, dynamic>> update({
    required int id,
    required String ascentDate,
    String? notes,
    required String token,
  }) async {
    throw UnimplementedError();
  }

  // DELETE /api/ascents/:id — Elimina una ascensión
  // Envía: token en header
  Future<void> delete(int id, String token) async {
    throw UnimplementedError();
  }

  // GET /api/ascents/user/:userId — Ascensiones de un usuario
  // Devuelve: List<Ascent>
  Future<List<dynamic>> getByUser(int userId, String token) async {
    throw UnimplementedError();
  }

  // GET /api/ascents/peak/:peakId — Ascensiones a un cim
  // Devuelve: List<Ascent>
  Future<List<dynamic>> getByPeak(int peakId, String token) async {
    throw UnimplementedError();
  }
}
