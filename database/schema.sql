-- Aquest script defineix l’estructura principal de la base de dades de CiMS.
-- Inclou les taules necessàries per gestionar usuaris, cims, ascensions,
-- estats personals, reptes mensuals, fotos i verificacions.
CREATE DATABASE IF NOT EXISTS cims_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE cims_db;

-- Aquesta taula guarda les comarques utilitzades per classificar els cims.
-- Permet filtrar el catàleg per territori i evitar noms de comarca duplicats.
CREATE TABLE IF NOT EXISTS regions (
  id         INT          NOT NULL AUTO_INCREMENT,
  name       VARCHAR(100) NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_regions_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Aquesta taula guarda els comptes dels usuaris registrats.
-- També permet associar una foto de perfil mitjançant una ruta interna del bucket.
CREATE TABLE IF NOT EXISTS users (
  id                 INT          NOT NULL AUTO_INCREMENT,
  first_name         VARCHAR(100) NOT NULL,
  last_name          VARCHAR(150) NOT NULL,
  email              VARCHAR(255) NOT NULL,
  password           VARCHAR(255) NOT NULL,
  is_active          TINYINT      NOT NULL DEFAULT 1,
  profile_photo_path VARCHAR(500) NULL,
  created_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Aquesta taula guarda el catàleg principal de cims.
-- Les coordenades permeten mostrar-los al mapa i donar suport a futures verificacions.
CREATE TABLE IF NOT EXISTS peaks (
  id          INT          NOT NULL AUTO_INCREMENT,
  name        VARCHAR(150) NOT NULL,
  altitude    INT          NOT NULL,
  latitude    DECIMAL(9,6) NOT NULL,
  longitude   DECIMAL(9,6) NOT NULL,
  description TEXT         NULL,
  created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_peaks_altitude (altitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Aquesta taula relaciona els cims amb les seves comarques.
-- Permet que un cim pugui estar associat a més d’un territori.
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

-- Aquesta taula registra les ascensions dels usuaris.
-- El camp is_date_locked permet bloquejar la data quan l’ascensió prové d’una verificació.
CREATE TABLE IF NOT EXISTS ascents (
  id             INT      NOT NULL AUTO_INCREMENT,
  user_id        INT      NOT NULL,
  peak_id        INT      NOT NULL,
  ascent_date    DATE     NULL,
  notes          TEXT,
  is_date_locked TINYINT  NOT NULL DEFAULT 0,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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

-- Aquesta taula guarda l’estat personal de cada cim per a cada usuari.
-- Permet marcar cims com a assolits, objectius o preferits.
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

-- Aquesta taula guarda els tokens temporals de recuperació de contrasenya.
-- Permet controlar la caducitat i evitar reutilitzacions del mateix token.
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

-- Aquesta taula defineix el repte mensual actiu del sistema.
-- Cada mes té una única plantilla global amb objectius progressius.
CREATE TABLE IF NOT EXISTS monthly_challenges (
  id         INT          NOT NULL AUTO_INCREMENT,
  `year`    SMALLINT     NOT NULL,
  `month`   TINYINT      NOT NULL,
  type      ENUM('peaks_completed', 'distinct_regions') NOT NULL,
  target_1  INT          NOT NULL,
  target_2  INT          NOT NULL,
  target_3  INT          NOT NULL,
  starts_at DATETIME     NOT NULL,
  ends_at   DATETIME     NOT NULL,
  created_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_monthly_challenges_period (`year`, `month`),
  INDEX idx_monthly_challenges_period (`year`, `month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Aquesta taula guarda el progrés de cada usuari dins d’un repte mensual.
-- Funciona com a resum calculat per consultar el progrés sense recalcular-lo constantment.
CREATE TABLE IF NOT EXISTS monthly_challenge_progress (
  id                    INT      NOT NULL AUTO_INCREMENT,
  user_id               INT      NOT NULL,
  monthly_challenge_id  INT      NOT NULL,
  current_progress      INT      NOT NULL DEFAULT 0,
  current_level         TINYINT  NOT NULL DEFAULT 0,
  level_1_completed_at  DATETIME NULL,
  level_2_completed_at  DATETIME NULL,
  level_3_completed_at  DATETIME NULL,
  created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_monthly_progress_user_challenge (user_id, monthly_challenge_id),
  INDEX idx_monthly_progress_user (user_id),
  INDEX idx_monthly_progress_challenge (monthly_challenge_id),
  CONSTRAINT fk_monthly_progress_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_monthly_progress_challenge
    FOREIGN KEY (monthly_challenge_id) REFERENCES monthly_challenges(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Aquesta taula guarda les fotos associades a una ascensió.
-- També permet marcar quina imatge actua com a evidència principal de verificació.
CREATE TABLE IF NOT EXISTS ascent_photos (
  id                       INT          NOT NULL AUTO_INCREMENT,
  ascent_id                INT          NOT NULL,
  storage_path             VARCHAR(500) NOT NULL,
  is_primary               TINYINT      NOT NULL DEFAULT 0,
  is_verification_evidence TINYINT      NOT NULL DEFAULT 0,
  created_at               DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_ascent_photos_ascent_id (ascent_id),
  INDEX idx_ascent_photos_created_at (created_at),
  INDEX idx_ascent_photos_verification_evidence (is_verification_evidence),
  CONSTRAINT fk_ascent_photos_ascent
    FOREIGN KEY (ascent_id) REFERENCES ascents(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Aquesta taula guarda la informació de verificació d’una ascensió.
-- Separa l’activitat registrada de la prova utilitzada per validar-la.
CREATE TABLE IF NOT EXISTS ascent_verifications (
  id                       INT          NOT NULL AUTO_INCREMENT,
  ascent_id                INT          NOT NULL,
  method                   ENUM('photo_exif', 'device_location', 'manual') NOT NULL,
  status                   ENUM('unverified', 'pending', 'verified', 'rejected') NOT NULL DEFAULT 'pending',
  captured_latitude        DECIMAL(9,6) NULL,
  captured_longitude       DECIMAL(9,6) NULL,
  captured_accuracy_meters DECIMAL(8,2) NULL,
  captured_at              DATETIME     NULL,
  distance_to_peak_meters  DECIMAL(10,2) NULL,
  checked_at               DATETIME     NULL,
  reason                   VARCHAR(255) NULL,
  created_at               DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at               DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_ascent_verifications_ascent_id (ascent_id),
  INDEX idx_ascent_verifications_status (status),
  INDEX idx_ascent_verifications_method (method),
  INDEX idx_ascent_verifications_checked_at (checked_at),
  CONSTRAINT fk_ascent_verifications_ascent
    FOREIGN KEY (ascent_id) REFERENCES ascents(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;