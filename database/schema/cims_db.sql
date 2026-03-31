-- ============================================================
-- CiMS Database Schema
-- Motor: MySQL 8.x, ENGINE=InnoDB, CHARSET=utf8mb4
-- Orden de creación respeta integridad referencial
-- ============================================================

CREATE DATABASE IF NOT EXISTS cims_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE cims_db;

-- ------------------------------------------------------------
-- 1. regions
-- Tabla de referencia. Sin dependencias externas.
-- ------------------------------------------------------------
CREATE TABLE regions (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_regions_name UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 2. users
-- Tabla de referencia. Sin dependencias externas.
-- ------------------------------------------------------------
CREATE TABLE users (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  first_name  VARCHAR(100) NOT NULL,
  last_name   VARCHAR(150) NOT NULL,
  email       VARCHAR(255) NOT NULL,
  password    VARCHAR(255) NOT NULL,  -- hash bcrypt, nunca texto plano
  is_active   TINYINT(1) NOT NULL DEFAULT 1,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_users_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 3. peaks
-- Depende de regions (region_id FK)
-- ------------------------------------------------------------
CREATE TABLE peaks (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(150) NOT NULL,
  altitude    INT NOT NULL,
  latitude    DECIMAL(9,6) NOT NULL,
  longitude   DECIMAL(9,6) NOT NULL,
  region_id   INT NOT NULL,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_peaks_region
    FOREIGN KEY (region_id) REFERENCES regions(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_peaks_region_id (region_id),
  INDEX idx_peaks_altitude  (altitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 4. ascents
-- Depende de users (user_id) y peaks (peak_id)
-- ------------------------------------------------------------
CREATE TABLE ascents (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT NOT NULL,
  peak_id      INT NOT NULL,
  ascent_date  DATE NOT NULL,
  notes        TEXT,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_ascents_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ascents_peak
    FOREIGN KEY (peak_id) REFERENCES peaks(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_ascents_user_id   (user_id),
  INDEX idx_ascents_peak_id   (peak_id),
  INDEX idx_ascents_date      (ascent_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- 5. peak_status
-- Depende de users y peaks. Unicidad compuesta user+peak.
-- ------------------------------------------------------------
CREATE TABLE peak_status (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT NOT NULL,
  peak_id      INT NOT NULL,
  is_completed TINYINT(1) NOT NULL DEFAULT 0,
  is_target    TINYINT(1) NOT NULL DEFAULT 0,
  is_favorite  TINYINT(1) NOT NULL DEFAULT 0,
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_peak_status_user_peak UNIQUE (user_id, peak_id),
  CONSTRAINT fk_peak_status_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_peak_status_peak
    FOREIGN KEY (peak_id) REFERENCES peaks(id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_peak_status_user_id (user_id),
  INDEX idx_peak_status_peak_id (peak_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
