--  Aquest script prepara la base de dades de CiMS des de zero.
--  És la primera fase del procés de seeding i s'encarrega de:
--    1. Eliminar la base de dades `cims_db` si existeix.
--    2. Crear-la de nou amb la codificació adequada (utf8mb4).
--    3. Carregar l'estructura completa de taules (schema.sql).
--    4. Carregar les dades base de les 43 comarques (seed_regions.sql).
--
--  El procés complet de seeding es divideix en tres passos perquè la càrrega
--  de cims es fa programàticament amb Node.js, i la càrrega de relacions
--  cims–comarques requereix que ambdues taules ja estiguin poblades:
--
--    Pas 1)  mysql -u root -p < bootstrap.sql
--    Pas 2)  node seeds/seed-peaks.js
--    Pas 3)  mysql -u root -p < bootstrap_post_peaks.sql
--
--  IMPORTANT:
--    - Aquest script ELIMINA la base de dades existent. Qualsevol dada
--      manual prèvia es perdrà. Pensat per a entorns de desenvolupament.
--    - Les rutes SOURCE són relatives al directori actual del client mysql.
--      Cal executar-lo des de la carpeta `database/`.
-- ─────────────────────────────────────────────────────────────────────────────

SET NAMES utf8mb4;

-- ── Recreació de la base de dades ────────────────────────────────────────────
DROP DATABASE IF EXISTS cims_db;
CREATE DATABASE cims_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE cims_db;

-- ── Càrrega de l'estructura ──────────────────────────────────────────────────
SOURCE schema.sql;

-- ── Càrrega de dades base ────────────────────────────────────────────────────
-- Només es carreguen les comarques aquí. Els cims es carreguen amb el seeder
-- de Node.js (`seeds/seed-peaks.js`) per llegir-los del CSV i la relació
-- cims–comarques es carrega amb `bootstrap_post_peaks.sql` un cop els pics
-- ja hi són a la base de dades.
SOURCE seeds/seed_regions.sql;

-- ── Validació intermèdia ─────────────────────────────────────────────────────
-- Comprovació ràpida que les comarques s'han carregat correctament.
-- Esperem 43 files (42 comarques + Aran).
SELECT 'regions_count' AS check_name, COUNT(*) AS total FROM regions;