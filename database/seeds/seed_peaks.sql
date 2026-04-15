-- Aquest script afegeix dades inicials a la base de dades del projecte CiMS.
-- La seva funció és carregar una primera selecció de cims i vincular-los amb la seva comarca
-- perquè l’aplicació pugui mostrar informació real des del primer moment.

USE cims_db;

INSERT INTO peaks (name, altitude, latitude, longitude) VALUES
('Comaloforno', 3029, 42.591382, 0.827834),
('Monteixo', 2905, 42.601739, 1.361638),
('Cim de Finestrelles', 2827, 42.414527, 2.133513),
('Pollegó Superior', 2506, 42.239945, 1.702926),
('Puigsacalm', 1513, 42.125169, 2.387916),
('Bellmunt (Sant Pere de Torelló)', 1247, 42.101499, 2.293714),
('Montgròs (el Bruc)', 1133, 41.600012, 1.805099),
('El Mont', 1123, 42.258882, 2.706309),
('La Mussara (Vilaplana) o Puig de la Torre', 1055, 41.257941, 1.055457),
('Torreta de Montsià', 763, 40.613614, 0.530309),
('Vulturó o Puig de la Canal Baridana', 2649, 42.285807, 1.636417),
('Cap de Boumort', 2077, 42.235018, 1.134659),
('Tossa Pelada', 2379, 42.190660, 1.522457),
('Penya Alta (la Pobla de Cérvoles)', 1016, 41.350664, 0.946305),
('Puig sa Cadires', 1174, 41.920555, 2.535255),
('La Mola (Gallifa)', 942, 41.702603, 2.122947),
('Turó de l''Home', 1706, 41.776490, 2.434813),
('Montalt (Dosrius)', 597, 41.604088, 2.495482),
('Roca de Migdia (Mont-ral)', 1022, 41.292595, 1.061509),
('El Tibidabo', 516, 41.422221, 2.118808),
('Miranda de Santa Magdalena', 1132, 41.588406, 1.826477),
('Mont Caro o Caro', 1441, 40.803130, 0.343109),
('Puig de la Talaia o Talaia de Montmell', 861, 41.335772, 1.466715),
('Sant Patllari', 646, 42.112146, 2.711716),
('Serrat del Moro (Marganell)', 1206, 41.606879, 1.815017);

INSERT INTO peak_regions (peak_id, region_id) VALUES
((SELECT id FROM peaks WHERE name = 'Comaloforno'), (SELECT id FROM regions WHERE name = 'Alta Ribagorça')),
((SELECT id FROM peaks WHERE name = 'Monteixo'), (SELECT id FROM regions WHERE name = 'Pallars Sobirà')),
((SELECT id FROM peaks WHERE name = 'Cim de Finestrelles'), (SELECT id FROM regions WHERE name = 'Ripollès')),
((SELECT id FROM peaks WHERE name = 'Pollegó Superior'), (SELECT id FROM regions WHERE name = 'Berguedà')),
((SELECT id FROM peaks WHERE name = 'Puigsacalm'), (SELECT id FROM regions WHERE name = 'Garrotxa')),
((SELECT id FROM peaks WHERE name = 'Bellmunt (Sant Pere de Torelló)'), (SELECT id FROM regions WHERE name = 'Osona')),
((SELECT id FROM peaks WHERE name = 'Montgròs (el Bruc)'), (SELECT id FROM regions WHERE name = 'Anoia')),
((SELECT id FROM peaks WHERE name = 'El Mont'), (SELECT id FROM regions WHERE name = 'Alt Empordà')),
((SELECT id FROM peaks WHERE name = 'La Mussara (Vilaplana) o Puig de la Torre'), (SELECT id FROM regions WHERE name = 'Baix Camp')),
((SELECT id FROM peaks WHERE name = 'Torreta de Montsià'), (SELECT id FROM regions WHERE name = 'Montsià')),
((SELECT id FROM peaks WHERE name = 'Vulturó o Puig de la Canal Baridana'), (SELECT id FROM regions WHERE name = 'Alt Urgell')),
((SELECT id FROM peaks WHERE name = 'Cap de Boumort'), (SELECT id FROM regions WHERE name = 'Pallars Jussà')),
((SELECT id FROM peaks WHERE name = 'Tossa Pelada'), (SELECT id FROM regions WHERE name = 'Solsonès')),
((SELECT id FROM peaks WHERE name = 'Penya Alta (la Pobla de Cérvoles)'), (SELECT id FROM regions WHERE name = 'Garrigues')),
((SELECT id FROM peaks WHERE name = 'Puig sa Cadires'), (SELECT id FROM regions WHERE name = 'Selva')),
((SELECT id FROM peaks WHERE name = 'La Mola (Gallifa)'), (SELECT id FROM regions WHERE name = 'Vallès Occidental')),
((SELECT id FROM peaks WHERE name = 'Turó de l''Home'), (SELECT id FROM regions WHERE name = 'Vallès Oriental')),
((SELECT id FROM peaks WHERE name = 'Montalt (Dosrius)'), (SELECT id FROM regions WHERE name = 'Maresme')),
((SELECT id FROM peaks WHERE name = 'Roca de Migdia (Mont-ral)'), (SELECT id FROM regions WHERE name = 'Alt Camp')),
((SELECT id FROM peaks WHERE name = 'El Tibidabo'), (SELECT id FROM regions WHERE name = 'Barcelonès')),
((SELECT id FROM peaks WHERE name = 'Miranda de Santa Magdalena'), (SELECT id FROM regions WHERE name = 'Baix Llobregat')),
((SELECT id FROM peaks WHERE name = 'Mont Caro o Caro'), (SELECT id FROM regions WHERE name = 'Baix Ebre')),
((SELECT id FROM peaks WHERE name = 'Puig de la Talaia o Talaia de Montmell'), (SELECT id FROM regions WHERE name = 'Baix Penedès')),
((SELECT id FROM peaks WHERE name = 'Sant Patllari'), (SELECT id FROM regions WHERE name = 'Pla de l''Estany')),
((SELECT id FROM peaks WHERE name = 'Serrat del Moro (Marganell)'), (SELECT id FROM regions WHERE name = 'Bages'));