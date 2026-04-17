-- bootstrap_cims_db.sql
-- Script mestre per inicialitzar la base de dades CiMS des de zero.
-- Executa'l des del client MySQL obert dins de la carpeta `database/`:
--   mysql -u root -p
--   SOURCE bootstrap.sql;
--
-- IMPORTANT:
-- 1) Aquest script elimina i recrea la base de dades `cims_db`.
-- 2) Les rutes SOURCE són relatives al directori actual del client MySQL.
-- 3) Per això has d'obrir mysql des de la carpeta `database/`.
--
-- Un cop executat aquest script, carrega els cims amb:
--   node seeds/seed-peaks.js

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