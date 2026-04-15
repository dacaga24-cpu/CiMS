-- Aquest script crea la base de dades principal de CiMS i defineix tota l’estructura inicial.
-- És rellevant perquè estableix on es guardaran les dades bàsiques de l’aplicació:
-- usuaris, cims, comarques, ascensions, estats personals i recuperació de contrasenya.
CREATE DATABASE IF NOT EXISTS cims_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE cims_db;

-- 1. Taula de regions (comarques)
CREATE TABLE IF NOT EXISTS regions (
  id         INT          NOT NULL AUTO_INCREMENT,
  name       VARCHAR(100) NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_regions_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. Taula d'usuaris
CREATE TABLE IF NOT EXISTS users (
  id         INT          NOT NULL AUTO_INCREMENT,
  first_name VARCHAR(100) NOT NULL,
  last_name  VARCHAR(150) NOT NULL,
  email      VARCHAR(255) NOT NULL,
  password   VARCHAR(255) NOT NULL,
  is_active  TINYINT      NOT NULL DEFAULT 1,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 3. Taula de cims
CREATE TABLE IF NOT EXISTS peaks (
  id         INT          NOT NULL AUTO_INCREMENT,
  name       VARCHAR(150) NOT NULL,
  altitude   INT          NOT NULL,
  latitude   DECIMAL(9,6) NOT NULL,
  longitude  DECIMAL(9,6) NOT NULL,
  description TEXT        NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_peaks_altitude (altitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 4. Taula que relaciona cims amb comarques
CREATE TABLE IF NOT EXISTS peak_regions (
  id         INT        NOT NULL AUTO_INCREMENT,
  peak_id    INT        NOT NULL,
  region_id  INT        NOT NULL,
  created_at DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  CONSTRAINT uq_peak_regions_peak_region UNIQUE (peak_id, region_id),
  CONSTRAINT fk_peak_regions_peak
    FOREIGN KEY (peak_id) REFERENCES peaks(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_peak_regions_region
    FOREIGN KEY (region_id) REFERENCES regions(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE INDEX idx_peak_regions_peak_id   ON peak_regions(peak_id);
CREATE INDEX idx_peak_regions_region_id ON peak_regions(region_id);

-- 5. Taula d'ascencions dels usuaris als cims
CREATE TABLE IF NOT EXISTS ascents (
  id          INT      NOT NULL AUTO_INCREMENT,
  user_id     INT      NOT NULL,
  peak_id     INT      NOT NULL,
  ascent_date DATE     NOT NULL,
  notes       TEXT,
  created_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_ascents_user_id (user_id),
  INDEX idx_ascents_peak_id (peak_id),
  INDEX idx_ascents_date    (ascent_date),
  CONSTRAINT fk_ascents_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ascents_peak
    FOREIGN KEY (peak_id) REFERENCES peaks(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 6. Taula per gestionar l'estat dels cims de cada usuari (completat, objectiu, preferit)
CREATE TABLE IF NOT EXISTS peak_status (
  id           INT        NOT NULL AUTO_INCREMENT,
  user_id      INT        NOT NULL,
  peak_id      INT        NOT NULL,
  is_completed TINYINT    NOT NULL DEFAULT 0,
  is_target    TINYINT    NOT NULL DEFAULT 0,
  is_favorite  TINYINT    NOT NULL DEFAULT 0,
  created_at   DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME   NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_peak_status_user_peak (user_id, peak_id),
  INDEX idx_peak_status_user_id (user_id),
  INDEX idx_peak_status_peak_id (peak_id),
  CONSTRAINT fk_peak_status_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_peak_status_peak
    FOREIGN KEY (peak_id) REFERENCES peaks(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. Taula per gestionar tokens de recuperació de contrassenya
CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id          INT          NOT NULL AUTO_INCREMENT,
  user_id     INT          NOT NULL,
  token       VARCHAR(255) NOT NULL,
  expires_at  DATETIME     NOT NULL,
  is_used     TINYINT      NOT NULL DEFAULT 0,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_password_reset_tokens_token (token),
  INDEX idx_password_reset_tokens_user_id (user_id),
  INDEX idx_password_reset_tokens_expires_at (expires_at),
  CONSTRAINT fk_password_reset_tokens_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4; 
