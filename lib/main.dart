import 'package:flutter/material.dart';
import 'database/sqlite_config.dart';
import 'database/route_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CiMS - Rutas de Montaña',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RouteRepository _repository = RouteRepository();
  List<MountainRoute> _routes = [];
  bool _isLoading = false;
  String _message = 'Inicializando base de datos SQLite...';

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    setState(() {
      _isLoading = true;
      _message = 'Inicializando base de datos SQLite...';
    });

    try {
      // La base de datos se inicializa automáticamente con SQLite
      // Cargar las rutas
      await _loadRoutes();

      setState(() {
        _message = 'Base de datos SQLite lista! Rutas cargadas: ${_routes.length}';
      });
    } catch (e) {
      setState(() {
        _message = 'Error al inicializar base de datos: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRoutes() async {
    final routes = await _repository.getAllRoutes();
    setState(() {
      _routes = routes;
    });
  }

  Future<void> _addSampleRoute() async {
    setState(() {
      _isLoading = true;
      _message = 'Añadiendo ruta de ejemplo...';
    });

    try {
      final route = MountainRoute(
        name: 'Ruta del Montseny',
        description: 'Hermosa ruta por el Parque Natural del Montseny',
        distance: 12.5,
        duration: 180,
        difficulty: 'media',
        latitude: 41.7698,
        longitude: 2.4469,
      );

      final id = await _repository.insertRoute(route);
      if (id != null) {
        await _loadRoutes();
        setState(() {
          _message = 'Ruta añadida con ID: $id';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error al añadir ruta: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CiMS - Rutas de Montaña'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      _message.contains('Error') ? Icons.error : Icons.check_circle,
                      size: 48,
                      color: _message.contains('Error') ? Colors.red : Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _addSampleRoute,
                icon: const Icon(Icons.add),
                label: const Text('Añadir Ruta de Ejemplo'),
              ),
            const SizedBox(height: 20),
            Expanded(
              child: _routes.isEmpty
                  ? const Center(
                      child: Text('No hay rutas. Añade una ruta de ejemplo.'),
                    )
                  : ListView.builder(
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              Icons.landscape,
                              color: route.difficulty == 'fácil'
                                  ? Colors.green
                                  : route.difficulty == 'media'
                                      ? Colors.orange
                                      : Colors.red,
                            ),
                            title: Text(route.name),
                            subtitle: Text(
                              '${route.distance} km - ${route.duration} min - ${route.difficulty}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                if (route.id != null) {
                                  await _repository.deleteRoute(route.id!);
                                  await _loadRoutes();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    SQLiteConfig.instance.closeDatabase();
    super.dispose();
  }
}
