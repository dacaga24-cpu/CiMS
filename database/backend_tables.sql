-- Script per crear les taules necessàries pel backend
-- Executar després de database/init.sql

USE cims_db;

-- Taula d'ascensions (registre de quan un usuari fa una ruta)
CREATE TABLE IF NOT EXISTS ascensions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  route_id INT NOT NULL,
  data_ascensio DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (route_id) REFERENCES mountain_routes(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_route_id (route_id),
  INDEX idx_data (data_ascensio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Taula d'estats de rutes (favorits, completats, planificats, etc.)
CREATE TABLE IF NOT EXISTS route_states (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  route_id INT NOT NULL,
  estat VARCHAR(50) NOT NULL COMMENT 'Estats: pendent, completat, favorit, planificat',
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (route_id) REFERENCES mountain_routes(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user_route (user_id, route_id),
  INDEX idx_estat (estat)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Verificar que totes les taules s'han creat correctament
SELECT 'Taules del backend creades correctament' AS status;
SHOW TABLES;

-- Mostrar l'estructura de les noves taules
DESCRIBE ascensions;
DESCRIBE route_states;
