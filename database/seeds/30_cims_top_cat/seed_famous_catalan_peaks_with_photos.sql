-- Seed de 30 cims famosos de Catalunya per al projecte CiMS.
-- Compatible amb l'estructura actual: peaks + peak_regions + regions.
-- Executar després de carregar schema.sql i seed_regions.sql.
-- Es pot executar més d'una vegada: actualitza els cims existents per nom i només crea les relacions que falten.

SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
SET CHARACTER SET utf8mb4;

USE cims_db;

-- Aquesta taula guarda les fotos públiques associades als cims del catàleg.
-- Permet separar les imatges fixes dels cims de les fotos personals d'ascensions.
CREATE TABLE IF NOT EXISTS peak_photos (
  id INT NOT NULL AUTO_INCREMENT,
  peak_id INT NOT NULL,
  storage_path VARCHAR(500) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  PRIMARY KEY (id),
  UNIQUE KEY uq_peak_photos_storage_path (storage_path),
  INDEX idx_peak_photos_peak_id (peak_id),

  CONSTRAINT fk_peak_photos_peak
    FOREIGN KEY (peak_id) REFERENCES peaks(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

START TRANSACTION;

DROP TEMPORARY TABLE IF EXISTS tmp_famous_peaks;
CREATE TEMPORARY TABLE tmp_famous_peaks (
  name        VARCHAR(150) NOT NULL,
  altitude    INT          NOT NULL,
  latitude    DECIMAL(9,6) NOT NULL,
  longitude   DECIMAL(9,6) NOT NULL,
  description TEXT         NULL,
  PRIMARY KEY (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TEMPORARY TABLE IF EXISTS tmp_famous_peak_photos;
CREATE TEMPORARY TABLE tmp_famous_peak_photos (
  peak_name    VARCHAR(150) NOT NULL,
  storage_path VARCHAR(500) NOT NULL,
  PRIMARY KEY (peak_name),
  UNIQUE KEY uq_tmp_famous_peak_photos_storage_path (storage_path)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tmp_famous_peaks (name, altitude, latitude, longitude, description) VALUES
('Pica d''Estats', 3143, 42.666946, 1.397888, 'El cim més alt de Catalunya i un dels grans objectius de l’alta muntanya pirinenca.'),
('Pedraforca', 2506, 42.238600, 1.706900, 'Muntanya icònica del Berguedà, molt reconeixible per la seva silueta de dos pollegons i l’enforcadura central.'),
('Puigmal', 2910, 42.383302, 2.116839, 'Cim clàssic del Pirineu oriental, molt vinculat a la vall de Núria i a les rutes d’alta muntanya accessibles.'),
('Bastiments', 2881, 42.426600, 2.233700, 'Un dels cims més coneguts del sector d’Ulldeter, amb grans vistes sobre el Pirineu oriental.'),
('Tossa Plana de Lles', 2905, 42.477700, 1.656900, 'Cim destacat de la Cerdanya, ampli i panoràmic, habitual en sortides d’alta muntanya sense grans dificultats tècniques.'),
('Puigpedrós', 2915, 42.487593, 1.761896, 'Gran cim de la Cerdanya, conegut per la seva amplitud i per les vistes cap al Pirineu central i oriental.'),
('Pic de Comaloforno', 3029, 42.591382, 0.827834, 'Cim principal del massís dels Besiberri i una de les ascensions d’alta muntanya més representatives de l’Alta Ribagorça.'),
('Besiberri Sud', 3023, 42.593797, 0.825995, 'Tresmil emblemàtic del sector dels Besiberri, molt proper al Comaloforno i associat a itineraris exigents.'),
('Punta Alta de Comalesbienes', 3014, 42.585692, 0.880299, 'Cim d’alta muntanya situat a l’entorn d’Aigüestortes, apreciat pel seu ambient alpí i les vistes sobre estanys i crestes.'),
('Tuc de Molières', 3010, 42.629470, 0.698561, 'Tresmil situat entre l’Aran i l’Alta Ribagorça, conegut com un dels grans cims occidentals de Catalunya.'),
('Montardo', 2833, 42.633337, 0.875341, 'Cim molt popular de l’entorn d’Aigüestortes, amb una silueta destacada i grans panoràmiques sobre la vall d’Aran.'),
('Els Encantats', 2748, 42.584900, 1.003400, 'Conjunt muntanyós icònic del Parc Nacional d’Aigüestortes i Estany de Sant Maurici, molt reconeixible des de l’estany.'),
('Pic de Sotllo', 3073, 42.667900, 1.390100, 'Cim veí de la Pica d’Estats, habitual en itineraris d’alta muntanya pel sostre de Catalunya.'),
('Montsent de Pallars', 2883, 42.515000, 1.045000, 'Cim panoràmic del Pallars, visible des de molts punts i molt valorat per les vistes sobre la vall Fosca i el Pirineu.'),
('Pic de Certascan', 2853, 42.712010, 1.277656, 'Cim destacat del Pirineu occidental català, proper a l’estany de Certascan i a un entorn d’alta muntanya molt característic.'),
('Pic de Salòria', 2788, 42.514458, 1.385150, 'Cim rellevant entre l’Alt Urgell i el Pallars Sobirà, amb una situació privilegiada per observar grans sectors del Pirineu.'),
('Comabona', 2548, 42.283688, 1.726298, 'Cim clàssic de la serra del Cadí, molt conegut per les seves panoràmiques sobre el Berguedà i la Cerdanya.'),
('Penyes Altes de Moixeró', 2276, 42.306291, 1.842475, 'Punt culminant del Moixeró, molt representatiu del Parc Natural del Cadí-Moixeró i de les rutes entre el Berguedà i la Cerdanya.'),
('Puigllançada', 2409, 42.300483, 1.935511, 'Cim conegut del sector de la Molina i Castellar de n’Hug, amb accés relativament popular i bones vistes de l’alta muntanya propera.'),
('Costabona', 2464, 42.416924, 2.343871, 'Cim fronterer del Pirineu oriental, habitual en rutes des de la zona de Setcases i amb panoràmiques àmplies cap al Canigó.'),
('el Taga', 2039, 42.280763, 2.209900, 'Cim molt popular del Ripollès, accessible i panoràmic, sovint utilitzat com a objectiu d’iniciació a l’alta muntanya.'),
('Puigsacalm', 1515, 42.124200, 2.393200, 'Cim emblemàtic entre la Garrotxa i Osona, molt conegut per les vistes sobre la vall d’en Bas i el paisatge prepirinenc.'),
('Matagalls', 1697, 41.808791, 2.382702, 'Un dels cims més populars del Montseny, amb molta tradició excursionista i un perfil clarament identificable.'),
('Turó de l''Home', 1706, 41.776900, 2.434100, 'Punt culminant del massís del Montseny, molt conegut per la seva accessibilitat i per les vistes sobre bona part de Catalunya.'),
('Les Agudes (Massís del Montseny)', 1706, 41.789325, 2.443955, 'Cim destacat del Montseny, proper al Turó de l’Home i molt habitual en travesses clàssiques del massís.'),
('Sant Jeroni (el Bruc)', 1236, 41.605365, 1.811457, 'Punt més alt de Montserrat, molt conegut per les seves vistes i per la seva importància dins l’excursionisme català.'),
('La Mola (Sant Llorenç del Munt)', 1104, 41.641700, 2.018100, 'Cim principal de Sant Llorenç del Munt, molt freqüentat i conegut pel monestir situat al capdamunt.'),
('Montcau (Sant Llorenç del Munt)', 1056, 41.675900, 2.020600, 'Cim arrodonit i molt popular del parc natural de Sant Llorenç del Munt i l’Obac, sovint combinat amb La Mola.'),
('Mont Caro', 1442, 40.803600, 0.343400, 'Cim més alt del massís dels Ports, referent muntanyenc del sud de Catalunya i gran mirador sobre l’Ebre.'),
('Puig de Bassegoda', 1373, 42.312791, 2.630777, 'Cim característic de l’Alta Garrotxa, amb una silueta molt reconeixible i una forta presència en l’excursionisme local.');

INSERT INTO tmp_famous_peak_photos (peak_name, storage_path) VALUES
('Pica d''Estats', 'images/01_pica_destats.jpg'),
('Pedraforca', 'images/02_pedraforca.jpg'),
('Puigmal', 'images/03_puigmal.jpg'),
('Bastiments', 'images/04_bastiments.jpg'),
('Tossa Plana de Lles', 'images/05_tossa_plana_de_lles.jpg'),
('Puigpedrós', 'images/06_puigpedros.jpg'),
('Pic de Comaloforno', 'images/07_comaloforno.jpg'),
('Besiberri Sud', 'images/08_besiberri_sud.jpg'),
('Punta Alta de Comalesbienes', 'images/09_punta_alta_de_comalesbienes.jpg'),
('Tuc de Molières', 'images/10_tuc_de_molieres.jpg'),
('Montardo', 'images/11_montardo.jpg'),
('Els Encantats', 'images/12_els_encantats.jpg'),
('Pic de Sotllo', 'images/13_pic_de_sotllo.jpg'),
('Montsent de Pallars', 'images/14_montsent_de_pallars.jpg'),
('Pic de Certascan', 'images/15_pic_de_certascan.jpg'),
('Pic de Salòria', 'images/16_pic_de_saloria.jpg'),
('Comabona', 'images/17_comabona.jpg'),
('Penyes Altes de Moixeró', 'images/18_penyes_altes_de_moixero.jpg'),
('Puigllançada', 'images/19_puigllancada.jpg'),
('Costabona', 'images/20_costabona.jpg'),
('el Taga', 'images/21_taga.jpg'),
('Puigsacalm', 'images/22_puigsacalm.jpg'),
('Matagalls', 'images/23_matagalls.jpg'),
('Turó de l''Home', 'images/24_turo_de_lhome.jpg'),
('Les Agudes (Massís del Montseny)', 'images/25_les_agudes.jpg'),
('Sant Jeroni (el Bruc)', 'images/26_sant_jeroni.jpg'),
('La Mola (Sant Llorenç del Munt)', 'images/27_la_mola.jpg'),
('Montcau (Sant Llorenç del Munt)', 'images/28_montcau.jpg'),
('Mont Caro', 'images/29_mont_caro.jpg'),
('Puig de Bassegoda', 'images/30_bassegoda.jpg');

-- S'insereixen només els cims que encara no existeixen amb el mateix nom.
INSERT INTO peaks (name, altitude, latitude, longitude, description)
SELECT t.name, t.altitude, t.latitude, t.longitude, t.description
FROM tmp_famous_peaks t
WHERE NOT EXISTS (
  SELECT 1
  FROM peaks p
  WHERE p.name COLLATE utf8mb4_unicode_ci = t.name COLLATE utf8mb4_unicode_ci
);

-- Si el cim ja existia, s'actualitzen coordenades, altitud i descripció.
UPDATE peaks p
JOIN tmp_famous_peaks t
  ON p.name COLLATE utf8mb4_unicode_ci = t.name COLLATE utf8mb4_unicode_ci
SET
  p.altitude = t.altitude,
  p.latitude = t.latitude,
  p.longitude = t.longitude,
  p.description = t.description;

DROP TEMPORARY TABLE IF EXISTS tmp_famous_peak_regions;
CREATE TEMPORARY TABLE tmp_famous_peak_regions (
  peak_name   VARCHAR(150) NOT NULL,
  region_name VARCHAR(100) NOT NULL,
  PRIMARY KEY (peak_name, region_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO tmp_famous_peak_regions (peak_name, region_name) VALUES
('Pica d''Estats', 'Pallars Sobirà'),
('Pedraforca', 'Berguedà'),
('Puigmal', 'Ripollès'),
('Puigmal', 'Cerdanya'),
('Bastiments', 'Ripollès'),
('Tossa Plana de Lles', 'Cerdanya'),
('Puigpedrós', 'Cerdanya'),
('Pic de Comaloforno', 'Alta Ribagorça'),
('Besiberri Sud', 'Alta Ribagorça'),
('Punta Alta de Comalesbienes', 'Alta Ribagorça'),
('Tuc de Molières', 'Val d''Aran'),
('Tuc de Molières', 'Alta Ribagorça'),
('Montardo', 'Val d''Aran'),
('Montardo', 'Alta Ribagorça'),
('Els Encantats', 'Pallars Sobirà'),
('Pic de Sotllo', 'Pallars Sobirà'),
('Montsent de Pallars', 'Pallars Jussà'),
('Montsent de Pallars', 'Pallars Sobirà'),
('Pic de Certascan', 'Pallars Sobirà'),
('Pic de Salòria', 'Alt Urgell'),
('Pic de Salòria', 'Pallars Sobirà'),
('Comabona', 'Berguedà'),
('Comabona', 'Cerdanya'),
('Penyes Altes de Moixeró', 'Berguedà'),
('Penyes Altes de Moixeró', 'Cerdanya'),
('Puigllançada', 'Berguedà'),
('Costabona', 'Ripollès'),
('el Taga', 'Ripollès'),
('Puigsacalm', 'Garrotxa'),
('Puigsacalm', 'Osona'),
('Matagalls', 'Osona'),
('Matagalls', 'Vallès Oriental'),
('Turó de l''Home', 'Vallès Oriental'),
('Turó de l''Home', 'Selva'),
('Les Agudes (Massís del Montseny)', 'Selva'),
('Les Agudes (Massís del Montseny)', 'Vallès Oriental'),
('Sant Jeroni (el Bruc)', 'Anoia'),
('Sant Jeroni (el Bruc)', 'Bages'),
('La Mola (Sant Llorenç del Munt)', 'Vallès Occidental'),
('Montcau (Sant Llorenç del Munt)', 'Bages'),
('Montcau (Sant Llorenç del Munt)', 'Vallès Occidental'),
('Mont Caro', 'Baix Ebre'),
('Puig de Bassegoda', 'Garrotxa'),
('Puig de Bassegoda', 'Alt Empordà');

-- Es creen les relacions cim-comarca sense duplicar-les.
INSERT INTO peak_regions (peak_id, region_id)
SELECT p.id, r.id
FROM tmp_famous_peak_regions t
JOIN peaks p
  ON p.name COLLATE utf8mb4_unicode_ci = t.peak_name COLLATE utf8mb4_unicode_ci
JOIN regions r
  ON r.name COLLATE utf8mb4_unicode_ci = t.region_name COLLATE utf8mb4_unicode_ci
WHERE NOT EXISTS (
  SELECT 1
  FROM peak_regions pr
  WHERE pr.peak_id = p.id
    AND pr.region_id = r.id
);

-- Es creen o actualitzen les fotos públiques dels cims sense dependre d'IDs escrits a mà.
-- El peak_id es resol a partir del nom del cim ja inserit a la taula peaks.
INSERT INTO peak_photos (peak_id, storage_path)
SELECT p.id, t.storage_path
FROM tmp_famous_peak_photos t
JOIN peaks p
  ON p.name COLLATE utf8mb4_unicode_ci = t.peak_name COLLATE utf8mb4_unicode_ci
ON DUPLICATE KEY UPDATE
  peak_id = VALUES(peak_id),
  updated_at = CURRENT_TIMESTAMP;

-- Validacions ràpides. Si missing_regions, missing_peaks o missing_photo_peaks retorna files, cal revisar noms.
SELECT 'famous_peaks_loaded' AS check_name, COUNT(*) AS total
FROM tmp_famous_peaks t
JOIN peaks p
  ON p.name COLLATE utf8mb4_unicode_ci = t.name COLLATE utf8mb4_unicode_ci;

SELECT 'famous_peak_regions_loaded' AS check_name, COUNT(*) AS total
FROM tmp_famous_peak_regions t
JOIN peaks p
  ON p.name COLLATE utf8mb4_unicode_ci = t.peak_name COLLATE utf8mb4_unicode_ci
JOIN regions r
  ON r.name COLLATE utf8mb4_unicode_ci = t.region_name COLLATE utf8mb4_unicode_ci
JOIN peak_regions pr
  ON pr.peak_id = p.id AND pr.region_id = r.id;

SELECT 'famous_peak_photos_loaded' AS check_name, COUNT(*) AS total
FROM tmp_famous_peak_photos t
JOIN peaks p
  ON p.name COLLATE utf8mb4_unicode_ci = t.peak_name COLLATE utf8mb4_unicode_ci
JOIN peak_photos pp
  ON pp.peak_id = p.id
 AND pp.storage_path COLLATE utf8mb4_unicode_ci = t.storage_path COLLATE utf8mb4_unicode_ci;

SELECT 'missing_photo_peaks' AS check_name, t.peak_name
FROM tmp_famous_peak_photos t
LEFT JOIN peaks p
  ON p.name COLLATE utf8mb4_unicode_ci = t.peak_name COLLATE utf8mb4_unicode_ci
WHERE p.id IS NULL
GROUP BY t.peak_name;

SELECT 'missing_regions' AS check_name, t.region_name
FROM tmp_famous_peak_regions t
LEFT JOIN regions r
  ON r.name COLLATE utf8mb4_unicode_ci = t.region_name COLLATE utf8mb4_unicode_ci
WHERE r.id IS NULL
GROUP BY t.region_name;

SELECT 'missing_peaks' AS check_name, t.name
FROM tmp_famous_peaks t
LEFT JOIN peaks p
  ON p.name COLLATE utf8mb4_unicode_ci = t.name COLLATE utf8mb4_unicode_ci
WHERE p.id IS NULL
GROUP BY t.name;

COMMIT;
