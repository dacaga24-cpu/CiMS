-- Seed de 25 cims extrets del CSV i compatibles amb la taula regions

INSERT INTO peaks (name, altitude, latitude, longitude, description) VALUES
('Pica d''Estats', 3144, 42.666946, 1.397888, NULL),
('Comaloforno', 3029, 42.591382, 0.827834, NULL),
('Puigmal', 2910, 42.383302, 2.116839, NULL),
('Pic de Peguera', 2983, 42.540532, 1.011946, NULL),
('Pic de Salòria', 2789, 42.514458, 1.385150, NULL),
('Pedró dels Quatre Batlles', 2386, 42.184750, 1.520875, NULL),
('Cap del Verd', 2284, 42.200833, 1.613694, NULL),
('Roc dels Quatre Alcaldes', 1893, 42.258105, 1.151097, NULL),
('Les Agudes (Massís del Montseny)', 1705, 41.789325, 2.443955, NULL),
('Matagalls', 1697, 41.808791, 2.382702, NULL),
('Sant Jeroni (el Bruc)', 1236, 41.605365, 1.811457, NULL),
('Puig de la Mola', 534, 41.319412, 1.847864, NULL),
('Mola d''Estat', 1127, 41.325521, 1.059159, NULL),
('La Gritella', 1093, 41.299595, 0.961011, NULL),
('Catinell', 1350, 40.758564, 0.289746, NULL),
('Tossal d''Engrilló o Tossal', 1072, 40.943166, 0.370761, NULL),
('Mola de la Roquerola', 1058, 41.320364, 1.065286, NULL),
('Puig de Bassegoda', 1373, 42.312791, 2.630777, NULL),
('Cingles de Sant Roc', 598, 42.015179, 2.655306, NULL),
('Turó de Coll Prunera', 889, 41.654386, 1.989969, NULL),
('El Tibidabo', 516, 41.422221, 2.118808, NULL),
('El Pi Candeler', 463, 41.492376, 2.224598, NULL),
('Milany', 1533, 42.165555, 2.289673, NULL),
('Cabrera (l''Esquirol)', 1308, 42.076041, 2.407235, NULL),
('Puigsapera', 1061, 41.860525, 2.445929, NULL);

INSERT INTO peak_regions (peak_id, region_id)
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Pallars Sobirà' WHERE p.name = 'Pica d''Estats'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Alta Ribagorça' WHERE p.name = 'Comaloforno'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Ripollès' WHERE p.name = 'Puigmal'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Pallars Jussà' WHERE p.name = 'Pic de Peguera'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Pallars Sobirà' WHERE p.name = 'Pic de Peguera'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Alt Urgell' WHERE p.name = 'Pic de Salòria'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Pallars Sobirà' WHERE p.name = 'Pic de Salòria'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Alt Urgell' WHERE p.name = 'Pedró dels Quatre Batlles'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Solsonès' WHERE p.name = 'Pedró dels Quatre Batlles'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Alt Urgell' WHERE p.name = 'Cap del Verd'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Berguedà' WHERE p.name = 'Cap del Verd'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Solsonès' WHERE p.name = 'Cap del Verd'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Alt Urgell' WHERE p.name = 'Roc dels Quatre Alcaldes'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Pallars Jussà' WHERE p.name = 'Roc dels Quatre Alcaldes'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Pallars Sobirà' WHERE p.name = 'Roc dels Quatre Alcaldes'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Selva' WHERE p.name = 'Les Agudes (Massís del Montseny)'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Vallès Oriental' WHERE p.name = 'Les Agudes (Massís del Montseny)'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Osona' WHERE p.name = 'Matagalls'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Vallès Oriental' WHERE p.name = 'Matagalls'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Anoia' WHERE p.name = 'Sant Jeroni (el Bruc)'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Bages' WHERE p.name = 'Sant Jeroni (el Bruc)'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Baix Llobregat' WHERE p.name = 'Sant Jeroni (el Bruc)'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Alt Penedès' WHERE p.name = 'Puig de la Mola'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Baix Llobregat' WHERE p.name = 'Puig de la Mola'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Garraf' WHERE p.name = 'Puig de la Mola'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Baix Camp' WHERE p.name = 'Mola d''Estat'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Conca de Barberà' WHERE p.name = 'Mola d''Estat'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Baix Camp' WHERE p.name = 'La Gritella'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Priorat' WHERE p.name = 'La Gritella'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Baix Ebre' WHERE p.name = 'Catinell'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Montsià' WHERE p.name = 'Catinell'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Baix Ebre' WHERE p.name = 'Tossal d''Engrilló o Tossal'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Terra Alta' WHERE p.name = 'Tossal d''Engrilló o Tossal'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Alt Camp' WHERE p.name = 'Mola de la Roquerola'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Conca de Barberà' WHERE p.name = 'Mola de la Roquerola'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Alt Empordà' WHERE p.name = 'Puig de Bassegoda'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Garrotxa' WHERE p.name = 'Puig de Bassegoda'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Garrotxa' WHERE p.name = 'Cingles de Sant Roc'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Gironès' WHERE p.name = 'Cingles de Sant Roc'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Selva' WHERE p.name = 'Cingles de Sant Roc'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Bages' WHERE p.name = 'Turó de Coll Prunera'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Vallès Occidental' WHERE p.name = 'Turó de Coll Prunera'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Barcelonès' WHERE p.name = 'El Tibidabo'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Barcelonès' WHERE p.name = 'El Pi Candeler'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Vallès Occidental' WHERE p.name = 'El Pi Candeler'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Vallès Oriental' WHERE p.name = 'El Pi Candeler'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Osona' WHERE p.name = 'Milany'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Ripollès' WHERE p.name = 'Milany'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Garrotxa' WHERE p.name = 'Cabrera (l''Esquirol)'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Osona' WHERE p.name = 'Cabrera (l''Esquirol)'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Osona' WHERE p.name = 'Puigsapera'
UNION ALL
SELECT p.id, r.id FROM peaks p JOIN regions r ON r.name = 'Selva' WHERE p.name = 'Puigsapera';