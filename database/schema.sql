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
-- profile_photo_path guarda la ruta relativa al bucket GCS de la foto de
-- perfil (format `profile-photos/{userId}/{uuid}.{ext}`), o NULL si l'usuari
-- no n'ha pujat cap. No es desa cap URL completa perquè el bucket o el
-- domini poden canviar entre entorns sense necessitat de migrar dades; les
-- URLs signades de visualització es generen al backend quan cal servir-les.
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

-- 7. Taula per gestionar tokens de recuperació de contrasenya
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

-- 8. Plantilla del repte mensual del sistema. Hi ha una sola fila per (any, mes)
-- perquè el repte és global: tots els usuaris veuen el mateix repte el mateix mes.
-- El tipus s'escull aleatòriament la primera vegada que es genera la plantilla
-- (creació "lazy" des del servei) i defineix com es comptarà el progrés.
-- Els tres targets són els llindars dels nivells 1, 2 i 3, sempre creixents.
-- Les marques starts_at/ends_at s'expressen en hora local de Madrid i es passen
-- al driver com a string 'YYYY-MM-DD HH:MM:SS' per evitar conversions implícites
-- de timezone, ja que la finestra del repte és sempre el mes natural (dia 1
-- 00:00:00 fins l'últim dia 23:59:59) i ha de ser estable amb independència
-- de la zona on corri el servidor.
CREATE TABLE IF NOT EXISTS monthly_challenges (
  id         INT          NOT NULL AUTO_INCREMENT,
  `year`     SMALLINT     NOT NULL,
  `month`    TINYINT      NOT NULL,
  type       ENUM('peaks_completed', 'distinct_regions') NOT NULL,
  target_1   INT          NOT NULL,
  target_2   INT          NOT NULL,
  target_3   INT          NOT NULL,
  starts_at  DATETIME     NOT NULL,
  ends_at    DATETIME     NOT NULL,
  created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_monthly_challenges_period (`year`, `month`),
  INDEX idx_monthly_challenges_period (`year`, `month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 9. Progrés de cada usuari sobre cada repte mensual. El progrés es manté com
-- a cache derivat de la taula ascents per no haver de recalcular-lo a cada
-- lectura, però sempre es pot reconstruir amb un recompute des del servei.
-- Els camps level_X_completed_at sellen l'instant exacte (hora Madrid) en què
-- l'usuari va superar cada nivell. Per decisió de producte, si l'usuari elimina
-- ascensions i el progrés baixa per sota d'un llindar ja superat, el segell
-- corresponent es torna a NULL i el nivell es desbloqueja.
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

-- 10. Fotos associades a una ascensió. La relació és 1-N: una mateixa
-- ascensió pot tenir una foto principal i diverses fotos addicionals que
-- l'usuari afegeix com a record de la sortida.
--
-- storage_path guarda únicament la ruta relativa dins del bucket de Google
-- Cloud Storage (ex: 'ascents/123/abc123.jpg'). No es desa cap URL completa
-- perquè el bucket o el domini poden canviar entre entorns sense necessitat
-- de migrar dades; les URLs públiques o signades es generen al backend
-- quan cal servir-les al frontend.
--
-- is_primary distingeix la foto principal de l'ascensió (1) de les fotos
-- de memòria addicionals (0). En el flux verificat futur, la foto principal
-- serà la que aporta les metadades EXIF (GPS + timestamp) que validen
-- l'ascens i passarà a ser immutable.
-- L'ON DELETE CASCADE garanteix que en eliminar una ascensió també
-- desapareguin les seves fotos a la BD; els blobs corresponents al bucket
-- s'esborren des del servei abans de la fila d'ascents per evitar orfes.
CREATE TABLE IF NOT EXISTS ascent_photos (
  id           INT          NOT NULL AUTO_INCREMENT,
  ascent_id    INT          NOT NULL,
  storage_path VARCHAR(500) NOT NULL,
  is_primary   TINYINT      NOT NULL DEFAULT 0,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_ascent_photos_ascent_id (ascent_id),
  INDEX idx_ascent_photos_created_at (created_at),
  CONSTRAINT fk_ascent_photos_ascent
    FOREIGN KEY (ascent_id) REFERENCES ascents(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
