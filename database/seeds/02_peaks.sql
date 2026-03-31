-- 02_peaks.sql
-- Seed: Catálogo de cims de Cataluña
-- PENDIENTE: Completar con la fuente de datos oficial (ICC — Institut Cartogràfic de Catalunya, o equivalent)
-- Por ahora, solo contiene ejemplos representativos.
-- Ejecutar después de 01_regions.sql

USE cims_db;

-- Ejemplos de cims reales de Cataluña
-- (name, altitude, latitude, longitude, region_id)
-- NOTA: region_id depende del orden de inserción de 01_regions.sql

INSERT INTO peaks (name, altitude, latitude, longitude, region_id) VALUES
  ('Pica d''Estats', 3143, 42.6672, 1.3975, 27),       -- Pallars Sobirà
  ('Puigmal', 2913, 42.3819, 2.0861, 32),               -- Ripollès
  ('Aneto (visible des de Catalunya)', 3404, 42.6312, 0.6572, 5), -- Alta Ribagorça
  ('Puig Pedrós', 2914, 42.4647, 1.8394, 15),           -- Cerdanya
  ('Taga', 2040, 42.2567, 2.1450, 32);                  -- Ripollès
