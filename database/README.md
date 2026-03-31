# CiMS — Base de datos

## Requisitos

- MySQL 8.x instalado y en ejecución

## Ejecución de los scripts

Ejecutar los scripts en este orden obligatorio (respetar la integridad referencial):

### 1. Crear la base de datos y las tablas

```bash
mysql -u root -p < schema/cims_db.sql
```

### 2. Insertar las comarcas (42 comarcas oficiales de Cataluña)

```bash
mysql -u root -p < seeds/01_regions.sql
```

### 3. Insertar los cims de ejemplo

```bash
mysql -u root -p < seeds/02_peaks.sql
```

## Notas

- El script `schema/cims_db.sql` crea la base de datos `cims_db` si no existe.
- El seed `02_peaks.sql` contiene solo datos de ejemplo. Está pendiente de completar con la fuente de datos oficial (ICC o equivalente).
- Todos los scripts usan `USE cims_db;` al inicio.
