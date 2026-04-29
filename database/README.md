# Database – CiMS

**Autors:** Edim Batalla, Marco Bia, Daniel Caravaca
**BemenFP – 2026**

---

## Inicialització de la base de dades en local

El procés d'inicialització de `cims_db` es divideix en **tres passos** que s'executen alternant el client MySQL i Node.js. Aquesta divisió és necessària perquè la càrrega de cims es fa programàticament des d'un fitxer CSV, i la càrrega de relacions cims–comarques requereix que tant els pics com les comarques ja estiguin a la base de dades.

Tots els passos s'executen des de la carpeta `database/` del projecte.

### Pas 1 — Estructura i comarques

Obre el client MySQL indicant la ruta on està instal·lat `mysql.exe`:

```bash
"Ruta\On\Esta\mysql.exe" -u usuari -p
```

#### Exemple (MySQL 8.0 per defecte a Windows)

```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
```

Un cop dins del client, executa el script de bootstrap:

```sql
SOURCE bootstrap.sql;
```

Això eliminarà i recrearà la base de dades `cims_db` des de zero, aplicarà l'esquema i carregarà les 43 comarques. Al final mostrarà un comptador de validació; ha de retornar `regions_count = 43`.

Un cop completat, surt del client MySQL amb `exit;`.

### Pas 2 — Càrrega de cims des del CSV

Des del terminal, situat a `database/`, executa el seeder Node.js:

```bash
node seeds/seed-peaks.js
```

Això llegirà el fitxer `data/peaks.csv` i carregarà els 1.000 cims a la taula `peaks`. La sortida mostrarà el nombre d'inserits i de saltats per duplicat.

### Pas 3 — Relacions cims–comarques i validacions finals

Torna a obrir el client MySQL:

```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
```

I executa el script de post-seed:

```sql
SOURCE bootstrap_post_peaks.sql;
```

Això carregarà les 1.000 relacions cims–comarques a la taula `peak_regions` i mostrarà un resum final amb el nombre de registres a totes les taules. Valors esperats en una càrrega neta:

| Taula             | Total esperat |
|-------------------|--------------:|
| regions           | 43            |
| peaks             | 1000          |
| peak_regions      | ≈ 1000        |
| users             | 0             |
| ascents           | 0             |
| peak_status       | 0             |

---

## Resum del flux complet

```bash
# Pas 1: estructura i comarques
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
mysql> SOURCE bootstrap.sql;
mysql> exit;

# Pas 2: cims
node seeds/seed-peaks.js

# Pas 3: relacions i validacions
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p
mysql> SOURCE bootstrap_post_peaks.sql;
mysql> exit;
```

Si el `Pas 2` falla a mig camí (per exemple per problema de connexió o un CSV malformat), pots reexecutar-lo sense haver de tornar a fer el `Pas 1`. El `INSERT IGNORE` del `seed-peaks.js` evita duplicats si la taula ja té registres parcials.