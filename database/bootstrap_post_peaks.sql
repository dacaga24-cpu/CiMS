--  Tercera i última fase del procés de seeding de CiMS.
--
--  Aquest script s'executa DESPRÉS d'haver carregat els cims a la base de
--  dades amb `node seeds/seed-peaks.js`. La seva funció és:
--    1. Carregar les relacions cims–comarques (taula peak_regions).
--    2. Validar que totes les taules tenen el nombre esperat de registres.
--
--  Per què cal un script separat:
--    El fitxer `seed-peak-regions.sql` resol els ids de pics i comarques
--    dinàmicament via subconsulta (WHERE p.name = '...' AND r.name = '...').
--    Per tant, requereix que tant `peaks` com `regions` ja estiguin poblades.
--    Com que `peaks` es carrega amb un script Node intermedi, aquesta fase
--    no es pot incloure dins del `bootstrap.sql` inicial.
--
--  Procés complet (recordatori):
--    Pas 1)  mysql -u root -p < bootstrap.sql
--    Pas 2)  node seeds/seed-peaks.js
--    Pas 3)  mysql -u root -p < bootstrap_post_peaks.sql   ← AQUEST SCRIPT
--
--  IMPORTANT:
--    - Si `seed-peaks.js` ha fallat o ha carregat un nombre incomplet de
--      cims, les subconsultes de `seed-peak-regions.sql` no trobaran
--      coincidència per a aquells noms i el `INSERT IGNORE` simplement
--      no inserirà la fila (no llençarà error). Reviseu el comptador de
--      `peak_regions_count` al final per detectar-ho.
-- ─────────────────────────────────────────────────────────────────────────────

USE cims_db;

-- ── Càrrega de relacions cims–comarques ──────────────────────────────────────
-- Aquest fitxer conté 1.000 sentències INSERT IGNORE que resolen els ids
-- dinàmicament. L'INSERT IGNORE aprofita la unique constraint
-- uq_peak_regions_peak_region per ser idempotent: si reexecuteu aquest
-- script, no es generen duplicats.
SOURCE seeds/seed-peak-regions.sql;

-- ── Validacions finals ───────────────────────────────────────────────────────
-- Comprovació que totes les taules tenen el nombre esperat de registres
-- després del procés complet de seeding.
--
-- Valors esperats en una càrrega neta:
--   regions_count       = 43      (42 comarques + Aran)
--   peaks_count         = 1000    (els 1.000 cims del CSV)
--   peak_regions_count  ≈ 1000    (una relació per pic)
--   users_count         = 0       (no hi ha usuaris precarregats)
--   ascents_count       = 0       (no hi ha ascensions precarregades)
--   peak_status_count   = 0       (no hi ha estats precarregats)

SELECT 'regions_count'      AS check_name, COUNT(*) AS total FROM regions;
SELECT 'peaks_count'        AS check_name, COUNT(*) AS total FROM peaks;
SELECT 'peak_regions_count' AS check_name, COUNT(*) AS total FROM peak_regions;
SELECT 'users_count'        AS check_name, COUNT(*) AS total FROM users;
SELECT 'ascents_count'      AS check_name, COUNT(*) AS total FROM ascents;
SELECT 'peak_status_count'  AS check_name, COUNT(*) AS total FROM peak_status;