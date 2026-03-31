// peak_service.dart
// Responsabilidad: Llamadas HTTP a los endpoints de cims.
// NO contiene lógica de negocio ni gestión de estado.

// import 'package:http/http.dart' as http;
// import '../core/constants/api_constants.dart';
// import '../models/peak.dart';

class PeakService {
  // GET /api/peaks — Devuelve todos los cims
  // Devuelve: List<Peak>
  Future<List<dynamic>> getAll() async {
    throw UnimplementedError();
  }

  // GET /api/peaks/:id — Devuelve un cim por ID
  // Devuelve: Peak
  Future<Map<String, dynamic>> getById(int id) async {
    throw UnimplementedError();
  }

  // GET /api/peaks/region/:regionId — Devuelve cims de una comarca
  // Devuelve: List<Peak>
  Future<List<dynamic>> getByRegion(int regionId) async {
    throw UnimplementedError();
  }

  // GET /api/peaks/altitude?min=X&max=Y — Filtra cims por altitud
  // Devuelve: List<Peak>
  Future<List<dynamic>> getByAltitude(int min, int max) async {
    throw UnimplementedError();
  }

  // GET /api/peaks/search?q=query — Busca cims por nombre
  // Devuelve: List<Peak>
  Future<List<dynamic>> search(String query) async {
    throw UnimplementedError();
  }
}
