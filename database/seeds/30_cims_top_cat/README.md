# Seed de cims famosos amb fotos — CiMS

Aquest paquet adapta el seed original perquè també ompli la taula `peak_photos`.

## Fitxers

- `seed_famous_catalan_peaks_with_photos.sql`: seed complet amb cims, comarques i fotos.
- `peak_photos_mapping.csv`: relació entre cada cim i el fitxer d'imatge.
- `famous_catalan_peaks_preview.csv`: revisió dels cims, coordenades, comarques i descripcions.
- `cims_fotos_catalunya.zip`: imatges dels 30 cims.

## Com funciona la relació amb les fotos

El seed no escriu IDs fixos. Primer insereix o actualitza els cims a `peaks` i després fa:

```sql
INSERT INTO peak_photos (peak_id, storage_path)
SELECT p.id, t.storage_path
FROM tmp_famous_peak_photos t
JOIN peaks p ON p.name = t.peak_name;
```

Així, cada foto queda relacionada amb l'ID real que tingui el cim en aquella base de dades.

## Ruta de les imatges

El camp `storage_path` utilitza les mateixes rutes que hi ha dins del ZIP de fotos, per exemple:

```text
images/01_pica_destats.jpg
images/02_pedraforca.jpg
```

Perquè funcioni directament, pugeu les imatges respectant aquesta carpeta `images/`.
Si preferiu guardar-les a `peaks/`, canvieu el prefix `images/` al seed abans d'executar-lo.

## Quan executar-lo

Executa'l després de tenir carregades les comarques:

```sql
SOURCE seed_famous_catalan_peaks_with_photos.sql;
```

El seed és idempotent: es pot executar més d'una vegada. Actualitza les dades dels cims existents per nom, evita duplicar relacions a `peak_regions` i actualitza `peak_photos` si el `storage_path` ja existeix.
