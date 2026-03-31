import 'package:sqflite/sqflite.dart';
import 'sqlite_config.dart';

// Modelo para representar una ruta de montaña
class MountainRoute {
  final int? id;
  final String name;
  final String description;
  final double distance; // en kilómetros
  final int duration; // en minutos
  final String difficulty; // fácil, media, difícil
  final double? latitude;
  final double? longitude;

  MountainRoute({
    this.id,
    required this.name,
    required this.description,
    required this.distance,
    required this.duration,
    required this.difficulty,
    this.latitude,
    this.longitude,
  });

  // Crear desde un mapa (resultado de SQLite)
  factory MountainRoute.fromMap(Map<String, dynamic> map) {
    return MountainRoute(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      distance: (map['distance'] as num).toDouble(),
      duration: map['duration'] as int,
      difficulty: map['difficulty'] as String,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'distance': distance,
      'duration': duration,
      'difficulty': difficulty,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

// Repositorio para gestionar las rutas de montaña
class RouteRepository {
  final SQLiteConfig _dbConfig = SQLiteConfig.instance;

  // Obtener la base de datos
  Future<Database> get _db async => await _dbConfig.database;

  // Insertar una nueva ruta
  Future<int> insertRoute(MountainRoute route) async {
    try {
      final db = await _db;
      final id = await db.insert(
        'mountain_routes',
        route.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Ruta insertada con ID: $id');
      return id;
    } catch (e) {
      print('Error al insertar ruta: $e');
      rethrow;
    }
  }

  // Obtener todas las rutas
  Future<List<MountainRoute>> getAllRoutes() async {
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query(
        'mountain_routes',
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        return MountainRoute.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error al obtener rutas: $e');
      return [];
    }
  }

  // Obtener una ruta por ID
  Future<MountainRoute?> getRouteById(int id) async {
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query(
        'mountain_routes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return MountainRoute.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('Error al obtener ruta: $e');
      return null;
    }
  }

  // Actualizar una ruta
  Future<bool> updateRoute(MountainRoute route) async {
    if (route.id == null) return false;

    try {
      final db = await _db;
      final count = await db.update(
        'mountain_routes',
        route.toMap(),
        where: 'id = ?',
        whereArgs: [route.id],
      );
      print('Ruta actualizada: ${count > 0}');
      return count > 0;
    } catch (e) {
      print('Error al actualizar ruta: $e');
      return false;
    }
  }

  // Eliminar una ruta
  Future<bool> deleteRoute(int id) async {
    try {
      final db = await _db;
      final count = await db.delete(
        'mountain_routes',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Ruta eliminada: ${count > 0}');
      return count > 0;
    } catch (e) {
      print('Error al eliminar ruta: $e');
      return false;
    }
  }

  // Buscar rutas por dificultad
  Future<List<MountainRoute>> getRoutesByDifficulty(String difficulty) async {
    try {
      final db = await _db;
      final List<Map<String, dynamic>> maps = await db.query(
        'mountain_routes',
        where: 'difficulty = ?',
        whereArgs: [difficulty],
        orderBy: 'name ASC',
      );

      return List.generate(maps.length, (i) {
        return MountainRoute.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error al buscar rutas por dificultad: $e');
      return [];
    }
  }

  // Contar total de rutas
  Future<int> getTotalRoutes() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM mountain_routes');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error al contar rutas: $e');
      return 0;
    }
  }
}
