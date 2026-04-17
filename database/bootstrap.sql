-- Aquest script principal prepara la base de dades de CiMS des de zero.
-- La seva funció és recrear l’estructura bàsica, carregar les dades inicials
-- i comprovar al final que la càrrega s’ha fet correctament.

-- Aquestes indicacions expliquen com executar l’script des del client de MySQL.
-- És important fer-ho des de la carpeta correcta perquè les rutes dels fitxers auxiliars funcionin bé.
--   mysql -u root -p
--   SOURCE bootstrap.sql;
--
-- IMPORTANT:
-- 1) Aquest script elimina i recrea la base de dades `cims_db`.
-- 2) Les rutes SOURCE són relatives al directori actual del client MySQL.
-- 3) Per això has d'obrir mysql des de la carpeta `database/`.

SET NAMES utf8mb4;
SET @OLD_FOREIGN_KEY_CHECKS = @@FOREIGN_KEY_CHECKS;
SET FOREIGN_KEY_CHECKS = 0;

DROP DATABASE IF EXISTS cims_db;

SET FOREIGN_KEY_CHECKS = @OLD_FOREIGN_KEY_CHECKS;

-- Crea l'estructura base
SOURCE schema.sql;

-- Carrega dades inicials
SOURCE seeds/seed_regions.sql;
-- seed_peaks.sql eliminat: els cims es carreguen via `node seeds/seed-peaks.js`

-- Validacions bàsiques post-càrrega
USE cims_db;

SELECT 'regions_count'      AS check_name, COUNT(*) AS total FROM regions;
SELECT 'peaks_count'        AS check_name, COUNT(*) AS total FROM peaks;
SELECT 'peak_regions_count' AS check_name, COUNT(*) AS total FROM peak_regions;
SELECT 'users_count'        AS check_name, COUNT(*) AS total FROM users;
SELECT 'ascents_count'      AS check_name, COUNT(*) AS total FROM ascents;
SELECT 'peak_status_count'  AS check_name, COUNT(*) AS total FROM peak_status;