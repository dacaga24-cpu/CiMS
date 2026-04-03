-- Script de inicialización de la base de datos CiMS
-- Rutas de Montaña

-- Crear la base de datos
CREATE DATABASE IF NOT EXISTS cims_db;
USE cims_db;

-- Crear la tabla de rutas de montaña
CREATE TABLE IF NOT EXISTS mountain_routes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  distance DECIMAL(10, 2) NOT NULL COMMENT 'Distancia en kilómetros',
  duration INT NOT NULL COMMENT 'Duración en minutos',
  difficulty VARCHAR(50) NOT NULL COMMENT 'Dificultad: fácil, media, difícil',
  latitude DECIMAL(10, 8) COMMENT 'Latitud GPS',
  longitude DECIMAL(11, 8) COMMENT 'Longitud GPS',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_difficulty (difficulty),
  INDEX idx_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insertar datos de ejemplo de rutas de montaña en Cataluña
INSERT INTO mountain_routes (name, description, distance, duration, difficulty, latitude, longitude)
VALUES
  ('Ruta del Montseny', 'Hermosa ruta por el Parque Natural del Montseny, ideal para familias', 12.5, 180, 'media', 41.7698, 2.4469),
  ('Camino de Montserrat', 'Ascenso clásico al monasterio de Montserrat con vistas espectaculares', 8.3, 120, 'fácil', 41.5933, 1.8384),
  ('Pedraforca', 'Ruta desafiante al emblemático Pedraforca, para excursionistas experimentados', 15.2, 300, 'difícil', 42.2396, 1.7024),
  ('Pica d''Estats', 'Ascenso al pico más alto de Cataluña, ruta exigente', 18.5, 420, 'difícil', 42.6669, 1.3978),
  ('Ruta del Carrilet', 'Antigua vía del tren, ahora ruta verde perfecta para bicicletas', 20.0, 150, 'fácil', 42.0063, 2.7644),
  ('Cavall Bernat', 'Ruta circular por Montserrat con el Cavall Bernat como protagonista', 6.8, 90, 'media', 41.5952, 1.8269),
  ('Sant Jeroni', 'Ascenso al punto más alto de Montserrat desde el monasterio', 5.4, 75, 'media', 41.5925, 1.8322),
  ('Matagalls', 'Subida al Matagalls, uno de los picos emblemáticos del Montseny', 9.2, 150, 'media', 41.7756, 2.4347);

-- Crear tabla de usuarios (para futuras funcionalidades)
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(100) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Crear tabla de favoritos (relación usuarios-rutas)
CREATE TABLE IF NOT EXISTS user_favorites (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  route_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (route_id) REFERENCES mountain_routes(id) ON DELETE CASCADE,
  UNIQUE KEY unique_favorite (user_id, route_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Crear tabla de comentarios/reviews
CREATE TABLE IF NOT EXISTS route_reviews (
  id INT AUTO_INCREMENT PRIMARY KEY,
  route_id INT NOT NULL,
  user_id INT NOT NULL,
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (route_id) REFERENCES mountain_routes(id) ON DELETE CASCADE,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Verificar que todo se ha creado correctamente
SELECT 'Base de datos CiMS inicializada correctamente' AS status;
SHOW TABLES;
