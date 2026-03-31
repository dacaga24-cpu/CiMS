# Configuración de SQLite para CiMS

## ✅ Ventajas de SQLite

- **Sin servidor**: No necesitas instalar MySQL ni ningún servidor
- **Portable**: El archivo `.db` se guarda con la app
- **Rápido**: Perfecto para aplicaciones móviles
- **Simple**: Funciona automáticamente sin configuración

## 🚀 Cómo funciona

La base de datos SQLite se crea automáticamente la primera vez que ejecutas la aplicación. **No necesitas hacer nada más.**

### Pasos para ejecutar:

1. **Instalar dependencias**:
   ```bash
   flutter pub get
   ```

2. **Ejecutar la aplicación**:
   ```bash
   flutter run
   ```

¡Eso es todo! La base de datos se crea automáticamente con 8 rutas de ejemplo.

## 📂 Ubicación del archivo de base de datos

El archivo `cims.db` se guarda automáticamente en:

- **Android**: `/data/data/com.example.cims/databases/cims.db`
- **iOS**: `Library/Application Support/cims.db`
- **Windows**: `%APPDATA%/com.example.cims/databases/cims.db`
- **Linux**: `~/.local/share/com.example.cims/databases/cims.db`

## 🗂️ Estructura de la base de datos

### Tabla `mountain_routes`

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | INTEGER | ID autoincremental (clave primaria) |
| name | TEXT | Nombre de la ruta |
| description | TEXT | Descripción detallada |
| distance | REAL | Distancia en kilómetros |
| duration | INTEGER | Duración en minutos |
| difficulty | TEXT | Dificultad (fácil, media, difícil) |
| latitude | REAL | Coordenada GPS (latitud) |
| longitude | REAL | Coordenada GPS (longitud) |
| created_at | TEXT | Fecha de creación |

### Otras tablas

- `users`: Usuarios de la aplicación
- `user_favorites`: Rutas favoritas de los usuarios
- `route_reviews`: Comentarios y valoraciones

## 🛠️ Ver la base de datos

### Opción 1: DB Browser for SQLite (Recomendado)

1. Descarga [DB Browser for SQLite](https://sqlitebrowser.org/)
2. Instala y abre la aplicación
3. Ve a "Abrir base de datos"
4. Busca el archivo `cims.db` en la ubicación de tu plataforma

### Opción 2: Extensión de VS Code

1. Instala la extensión "SQLite Viewer" en VS Code
2. Abre el archivo `cims.db`

### Opción 3: Línea de comandos

```bash
# Encontrar el archivo (Android con adb)
adb shell
run-as com.example.cims
cd databases
cat cims.db

# O copiar el archivo a tu computadora
adb pull /data/data/com.example.cims/databases/cims.db .
```

## 📊 Datos de ejemplo

La aplicación incluye 8 rutas de montaña de Cataluña:

1. Ruta del Montseny
2. Camino de Montserrat
3. Pedraforca
4. Pica d'Estats
5. Ruta del Carrilet
6. Cavall Bernat
7. Sant Jeroni
8. Matagalls

## 🔄 Resetear la base de datos

Si quieres empezar desde cero:

1. **Desinstala la app** del dispositivo/emulador
2. **Vuelve a instalar** con `flutter run`

O modifica el código para eliminar y recrear la base de datos.

## 💡 Consejos

- SQLite es **perfecto para desarrollo y producción** en apps móviles
- Puedes usar SQLite para sincronizar con un servidor backend más adelante
- Los datos persisten entre ejecuciones de la app
- Es seguro para datos sensibles (en el dispositivo del usuario)

## 🆚 SQLite vs MySQL

| Característica | SQLite | MySQL |
|---------------|--------|-------|
| Instalación | ❌ No requiere | ✅ Requiere servidor |
| Configuración | ❌ Automática | ✅ Manual |
| Móviles | ✅ Perfecto | ❌ No recomendado |
| Multiusuario | ❌ Un usuario | ✅ Múltiples usuarios |
| Tamaño | ✅ Ligero | ⚠️ Pesado |
| Portabilidad | ✅ Alta | ❌ Baja |

**Para CiMS (app móvil)**: SQLite es la mejor opción.
