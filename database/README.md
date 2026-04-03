# Scripts de Base de Datos CiMS

⚠️ **NOTA**: Este proyecto ahora usa **SQLite** en lugar de MySQL.

Los scripts SQL en esta carpeta son de referencia para MySQL, pero **ya no se usan**.

## Configuración actual: SQLite

La base de datos SQLite se configura automáticamente en:
- `lib/database/sqlite_config.dart` - Configuración de SQLite
- `lib/database/route_repository.dart` - Operaciones CRUD

**No necesitas ejecutar scripts SQL manualmente.** Todo se crea automáticamente al ejecutar la app.

---

## Scripts SQL (Referencia MySQL - No utilizados)

## Archivos

### `init.sql`
Script de inicialización completo que:
- Crea la base de datos `cims_db`
- Crea todas las tablas necesarias
- Inserta datos de ejemplo (8 rutas de montaña)

**Uso:**
```bash
mysql -u root -p < database/init.sql
```

### `backup.sql` (Generado automáticamente)
Backup de la base de datos generado con el script de backup.

## Comandos útiles

### Inicializar la base de datos
```bash
mysql -u root -p < database/init.sql
```

### Hacer backup de la base de datos
```bash
mysqldump -u root -p cims_db > database/backup.sql
```

### Restaurar desde backup
```bash
mysql -u root -p cims_db < database/backup.sql
```

### Conectar a la base de datos
```bash
mysql -u root -p cims_db
```

### Ver las tablas
```sql
USE cims_db;
SHOW TABLES;
```

### Ver todas las rutas
```sql
SELECT * FROM mountain_routes;
```

## Estructura de tablas

### mountain_routes
Tabla principal con las rutas de montaña:
- `id`: ID autoincremental
- `name`: Nombre de la ruta
- `description`: Descripción detallada
- `distance`: Distancia en km
- `duration`: Duración en minutos
- `difficulty`: Nivel (fácil, media, difícil)
- `latitude`, `longitude`: Coordenadas GPS
- `created_at`, `updated_at`: Fechas de creación y actualización

### users
Usuarios de la aplicación (para futuras funcionalidades)

### user_favorites
Rutas favoritas de los usuarios

### route_reviews
Comentarios y valoraciones de las rutas

## Notas importantes

⚠️ **NO guardar en el repositorio:**
- Archivos binarios de MySQL (.ibd, .frm)
- Archivos con contraseñas o credenciales
- Backups grandes (añadir a .gitignore si son >1MB)

✅ **Sí guardar en el repositorio:**
- Scripts SQL (.sql)
- Scripts de migración
- Datos de ejemplo/seed
