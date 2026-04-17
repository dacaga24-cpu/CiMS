# Database – CiMS APP

**Autors:** Edim Batalla, Marco Bia, Daniel Caravaca
**BemenFP – 2026**

---

## Inicialització de la base de dades en local

Obre un terminal a la carpeta `database/` del projecte i executa el client MySQL indicant la ruta on està instal·lat `mysql.exe`:

```bash
"Ruta\On\Esta\mysql.exe" -u usuari -p
```

### Exemple (MySQL 8.0 per defecte a Windows)

```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
```

Un cop dins del client MySQL, executa el script de bootstrap:

```sql
SOURCE bootstrap.sql;
```

Això eliminarà i recrearà la base de dades `cims_db` des de zero,
aplicant l'esquema i les dades inicials automàticament.

Un cop completat, surt del client MySQL i executa el seeding de cims
des del terminal, situat a la carpeta `database/`:

```bash
node seeds/seed-peaks.js
```

Això carregarà tots els cims des del fitxer `data/peaks.csv` a la base de dades.