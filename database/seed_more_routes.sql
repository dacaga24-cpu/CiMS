-- Script para añadir más rutas de ejemplo a la base de datos
-- Ejecutar después de init.sql si quieres más datos de prueba

USE cims_db;

-- Rutas adicionales de los Pirineos
INSERT INTO mountain_routes (name, description, distance, duration, difficulty, latitude, longitude)
VALUES
  ('Lago de San Mauricio', 'Ruta circular por el Parque Nacional de Aigüestortes', 9.5, 180, 'fácil', 42.5789, 0.9876),
  ('Aneto por Renclusa', 'Ascensión al pico más alto de los Pirineos', 20.4, 540, 'difícil', 42.6314, 0.6570),
  ('Coma Pedrosa', 'Pico más alto de Andorra, vista panorámica', 12.8, 240, 'media', 42.5736, 1.4425),
  ('Puigmal', 'Frontera entre España y Francia, ruta clásica', 14.3, 270, 'media', 42.4034, 2.1276),

  -- Rutas de costa
  ('Camí de Ronda - Costa Brava', 'Espectacular sendero costero por la Costa Brava', 25.0, 360, 'media', 41.8989, 3.1633),
  ('Cap de Creus', 'Ruta al punto más oriental de la península', 11.2, 150, 'fácil', 42.3189, 3.3161),

  -- Rutas del Pirineo Oriental
  ('Canigó desde Mariailles', 'Montaña sagrada de Cataluña', 16.7, 420, 'difícil', 42.5182, 2.4564),
  ('Bastiments', 'Ruta familiar por el Valle de Núria', 7.5, 120, 'fácil', 42.3898, 2.1589),
  ('Puigmal desde Núria', 'Ascensión invernal al Puigmal', 13.5, 300, 'media', 42.3898, 2.1589),

  -- Rutas del Berguedà
  ('Serra del Cadí - Pedraforca', 'Travesía entre dos emblemáticos', 22.0, 480, 'difícil', 42.2396, 1.7024),
  ('Tosa d''Alp', 'Pico más alto de la provincia de Girona', 18.3, 360, 'difícil', 42.3456, 1.9789),

  -- Rutas urbanas/periurbanas Barcelona
  ('Carretera de les Aigües', 'Ruta panorámica sobre Barcelona', 8.0, 90, 'fácil', 41.4102, 2.1289),
  ('Tibidabo - Torre de Collserola', 'Punto más alto de Barcelona', 5.2, 75, 'fácil', 41.4231, 2.1189),

  -- Rutas del Montseny (más)
  ('Turó de l''Home desde Santa Fe', 'Ascensión al punto más alto del Montseny', 10.5, 210, 'media', 41.7698, 2.4469),
  ('Les Agudes', 'Segundo pico más alto del Montseny', 8.9, 165, 'media', 41.7789, 2.4512);

-- Verificar inserción
SELECT COUNT(*) as 'Total de rutas' FROM mountain_routes;
SELECT difficulty, COUNT(*) as 'Cantidad' FROM mountain_routes GROUP BY difficulty;
