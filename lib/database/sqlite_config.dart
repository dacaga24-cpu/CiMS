import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLiteConfig {
  static const String _databaseName = 'cims.db';
  static const int _databaseVersion = 1;

  // Singleton para mantener una única instancia
  static SQLiteConfig? _instance;
  static Database? _database;

  SQLiteConfig._();

  static SQLiteConfig get instance {
    _instance ??= SQLiteConfig._();
    return _instance!;
  }

  // Obtener la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos
  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    print('Ruta de la base de datos: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // Crear las tablas
  Future<void> _onCreate(Database db, int version) async {
    print('Creando tablas de la base de datos...');

    // Tabla de rutas de montaña
    await db.execute('''
      CREATE TABLE mountain_routes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        distance REAL NOT NULL,
        duration INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de usuarios
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Tabla de favoritos
    await db.execute('''
      CREATE TABLE user_favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        route_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (route_id) REFERENCES mountain_routes(id) ON DELETE CASCADE,
        UNIQUE(user_id, route_id)
      )
    ''');

    // Tabla de reseñas
    await db.execute('''
      CREATE TABLE route_reviews (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        route_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        rating INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
        comment TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (route_id) REFERENCES mountain_routes(id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    print('Tablas creadas correctamente');

    // Insertar datos de ejemplo
    await _insertSampleData(db);
  }

  // Insertar datos de ejemplo
  Future<void> _insertSampleData(Database db) async {
    print('Insertando datos de ejemplo...');

    final routes = [
      {
        'name': 'Ruta del Montseny',
        'description': 'Hermosa ruta por el Parque Natural del Montseny',
        'distance': 12.5,
        'duration': 180,
        'difficulty': 'media',
        'latitude': 41.7698,
        'longitude': 2.4469,
      },
      {
        'name': 'Camino de Montserrat',
        'description': 'Ascenso al monasterio de Montserrat con vistas espectaculares',
        'distance': 8.3,
        'duration': 120,
        'difficulty': 'fácil',
        'latitude': 41.5933,
        'longitude': 1.8384,
      },
      {
        'name': 'Pedraforca',
        'description': 'Ruta desafiante al emblemático Pedraforca',
        'distance': 15.2,
        'duration': 300,
        'difficulty': 'difícil',
        'latitude': 42.2396,
        'longitude': 1.7024,
      },
      {
        'name': 'Pica d\'Estats',
        'description': 'Ascenso al pico más alto de Cataluña',
        'distance': 18.5,
        'duration': 420,
        'difficulty': 'difícil',
        'latitude': 42.6669,
        'longitude': 1.3978,
      },
      {
        'name': 'Ruta del Carrilet',
        'description': 'Antigua vía del tren, ahora ruta verde',
        'distance': 20.0,
        'duration': 150,
        'difficulty': 'fácil',
        'latitude': 42.0063,
        'longitude': 2.7644,
      },
      {
        'name': 'Cavall Bernat',
        'description': 'Ruta circular por Montserrat',
        'distance': 6.8,
        'duration': 90,
        'difficulty': 'media',
        'latitude': 41.5952,
        'longitude': 1.8269,
      },
      {
        'name': 'Sant Jeroni',
        'description': 'Ascenso al punto más alto de Montserrat',
        'distance': 5.4,
        'duration': 75,
        'difficulty': 'media',
        'latitude': 41.5925,
        'longitude': 1.8322,
      },
      {
        'name': 'Matagalls',
        'description': 'Subida al Matagalls, pico emblemático del Montseny',
        'distance': 9.2,
        'duration': 150,
        'difficulty': 'media',
        'latitude': 41.7756,
        'longitude': 2.4347,
      },
    ];

    for (final route in routes) {
      await db.insert('mountain_routes', route);
    }

    print('${routes.length} rutas insertadas correctamente');
  }

  // Cerrar la base de datos
  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('Base de datos cerrada');
    }
  }

  // Eliminar la base de datos (útil para desarrollo)
  Future<void> deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('Base de datos eliminada');
  }
}
