# CiMS - Aplicació de Rutes de Muntanya

> Projecte Intermodular DAM - BemenFP 2026

Aplicació mòbil per gestionar i descobrir rutes de muntanya a Catalunya, amb backend API REST i base de dades híbrida (SQLite + MySQL).

## 👥 Autors

- **Edim Batalla**
- **Marco Bia**
- **Daniel Caravaca**

---

## 📱 Descripció del Projecte

**CiMS** és una aplicació multiplataforma desenvolupada amb Flutter que permet als usuaris:

- Descobrir i explorar rutes de muntanya a Catalunya
- Gestionar favorits i planificar ascensions
- Registrar ascensions completades amb notes
- Consultar estadístiques personals
- Sincronització amb servidor backend (opcional)

### Tecnologies

| Component | Tecnologia |
|-----------|-----------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Node.js + Express |
| **Base de dades local** | SQLite |
| **Base de dades servidor** | MySQL |
| **Autenticació** | JWT (JSON Web Tokens) |
| **Plataformes** | Android, iOS, Windows, Linux, macOS, Web |

---

## 🚀 Guia d'Instal·lació Ràpida

### Prerequisits

- **Flutter SDK** (>= 2.19.0) - [Descarregar aquí](https://flutter.dev/docs/get-started/install)
- **Node.js** (>= v14) - [Descarregar aquí](https://nodejs.org/)
- **MySQL** (>= v5.7) - [Descarregar aquí](https://dev.mysql.com/downloads/)
- **Git**

### 1️⃣ Clonar el Repositori

```bash
git clone https://github.com/dacaga24-cpu/CiMs.git
cd CiMs
```

### 2️⃣ Configurar la App Flutter

```bash
# Instal·lar dependències
flutter pub get

# Executar l'aplicació (només SQLite local, sense backend)
flutter run
```

La base de dades SQLite es crea automàticament amb dades de prova.

### 3️⃣ Configurar el Backend (Opcional)

```bash
# Entrar a la carpeta backend
cd backend

# Instal·lar dependències
npm install

# Configurar variables d'entorn
cp .env.example .env
# Editar .env amb les teves credencials MySQL

# Crear la base de dades MySQL
mysql -u root -p < ../database/init.sql
mysql -u root -p < ../database/backend_tables.sql
mysql -u root -p < ../database/seed_more_routes.sql

# Iniciar el servidor
npm run dev
```

El servidor backend s'iniciarà a `http://localhost:3000`

### 4️⃣ Connectar l'App al Backend

Modifica la configuració de l'app per apuntar al servidor backend (si vols usar MySQL en lloc de SQLite).

---

## 📂 Estructura del Projecte

```
CiMs/
├── lib/                          # Codi font de l'aplicació Flutter
│   ├── main.dart                 # Punt d'entrada de l'app
│   └── database/                 # Configuració de SQLite local
│       ├── sqlite_config.dart    # Configuració i creació de taules
│       └── route_repository.dart # Repository per accedir a dades
│
├── backend/                      # API REST amb Node.js
│   ├── src/
│   │   ├── config/               # Configuració (DB, etc.)
│   │   ├── controllers/          # Lògica de negoci
│   │   ├── middleware/           # Auth, validació, errors
│   │   ├── models/               # Models de dades
│   │   └── routes/               # Definició d'endpoints
│   ├── .env.example              # Plantilla de configuració
│   ├── package.json              # Dependències Node.js
│   ├── server.js                 # Punt d'entrada del servidor
│   └── README.md                 # Documentació del backend
│
├── database/                     # Scripts SQL
│   ├── init.sql                  # Crear taules base
│   ├── backend_tables.sql        # Taules específiques backend
│   ├── seed_more_routes.sql      # Dades de prova
│   └── README.md                 # Documentació de la BD
│
├── test/                         # Tests de l'aplicació
├── android/                      # Configuració Android
├── ios/                          # Configuració iOS
├── windows/                      # Configuració Windows
├── linux/                        # Configuració Linux
├── macos/                        # Configuració macOS
├── web/                          # Configuració Web
│
├── pubspec.yaml                  # Dependències Flutter
├── DATABASE_SETUP.md             # Guia de configuració SQLite
└── README.md                     # Aquest fitxer
```

---

## 🗂️ Base de Dades

El projecte suporta **dues opcions**:

### Opció 1: SQLite (Local, per defecte)

- Perfecte per desenvolupament i ús individual
- Es crea automàticament al executar l'app
- No requereix cap configuració
- **Guia completa:** [DATABASE_SETUP.md](DATABASE_SETUP.md)

### Opció 2: MySQL (Servidor, opcional)

- Per producció i múltiples usuaris
- Requereix backend Node.js en execució
- Sincronització de dades entre dispositius
- **Guia completa:** [backend/README.md](backend/README.md)

### Taules principals

| Taula | Descripció |
|-------|------------|
| `mountain_routes` | Rutes de muntanya (cims) |
| `users` | Usuaris de l'aplicació |
| `ascensions` | Ascensions registrades |
| `route_states` | Estats de rutes (favorit, planificat, completat) |
| `user_favorites` | Favorits dels usuaris (SQLite) |
| `route_reviews` | Comentaris i valoracions (SQLite) |

---

## 🌐 API Backend

### Endpoints Principals

**Autenticació:**
- `POST /api/auth/register` - Registrar usuari
- `POST /api/auth/login` - Iniciar sessió
- `GET /api/auth/profile` - Perfil d'usuari

**Rutes/Cims:**
- `GET /api/cims` - Obtenir tots els cims
- `GET /api/cims/:id` - Obtenir cim per ID
- `POST /api/cims` - Crear nou cim (autenticat)

**Ascensions:**
- `GET /api/ascensions` - Les meves ascensions
- `POST /api/ascensions` - Registrar ascensió
- `GET /api/ascensions/stats` - Estadístiques

**Estats:**
- `GET /api/estats` - Els meus estats
- `POST /api/estats/favorite/:id` - Toggle favorit
- `GET /api/estats/favorites` - Obtenir favorits

**Documentació completa:** [backend/README.md](backend/README.md)

---

## 🛠️ Comandes Útils

### Flutter

```bash
# Executar l'aplicació
flutter run

# Executar en un dispositiu específic
flutter devices
flutter run -d <device_id>

# Build per Android
flutter build apk

# Build per iOS
flutter build ios

# Executar tests
flutter test

# Netejar cache
flutter clean
flutter pub get
```

### Backend

```bash
# Mode desenvolupament (auto-reload)
npm run dev

# Mode producció
npm start

# Instal·lar dependències
npm install
```

### Base de Dades

```bash
# Importar taules MySQL
mysql -u root -p cims_db < database/init.sql

# Exportar backup
mysqldump -u root -p cims_db > backup.sql

# Accedir a MySQL
mysql -u root -p cims_db
```

---

## 🧪 Testing

```bash
# Executar tots els tests
flutter test

# Executar un test específic
flutter test test/widget_test.dart

# Tests amb cobertura
flutter test --coverage
```

---

## 📦 Dependències Principals

### Flutter (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  sqflite: ^2.3.0           # Base de dades SQLite
  path_provider: ^2.1.1      # Accés a directoris del sistema
  path: ^1.8.3               # Manipulació de paths
```

### Backend (`package.json`)

```json
{
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.5",
    "dotenv": "^16.3.1",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "cors": "^2.8.5",
    "express-validator": "^7.0.1"
  }
}
```

---

## 🔒 Seguretat i Bones Pràctiques

- **NEVER** pujar el fitxer `backend/.env` (credencials)
- Canviar `JWT_SECRET` en producció
- Usar HTTPS en entorns de producció
- Validar totes les entrades d'usuari
- Configurar CORS adequadament
- Usar `.gitignore` correctament

---

## 🐛 Resolució de Problemes

### Error: "No s'han trobat rutes"

- Verifica que la base de dades s'ha creat correctament
- Comprova que els scripts SQL s'han executat

### Error: "Cannot connect to MySQL"

- Verifica que MySQL està en execució
- Comprova les credencials al fitxer `.env`
- Assegura't que la base de dades `cims_db` existeix

### Error: "Flutter SDK not found"

```bash
flutter doctor
```

### Error de dependències

```bash
flutter clean
flutter pub get
cd backend && npm install
```

---

## 📄 Documentació Addicional

- [DATABASE_SETUP.md](DATABASE_SETUP.md) - Guia de configuració SQLite
- [backend/README.md](backend/README.md) - Documentació completa del backend API
- [database/README.md](database/README.md) - Esquema de la base de dades

---

## 🤝 Contribuir

1. Fes un fork del projecte
2. Crea una branca per la teva funcionalitat (`git checkout -b feature/nova-funcionalitat`)
3. Commit els teus canvis (`git commit -m 'Afegir nova funcionalitat'`)
4. Push a la branca (`git push origin feature/nova-funcionalitat`)
5. Obre un Pull Request

### Convencions de Commits

- `feat:` Nova funcionalitat
- `fix:` Correcció de bug
- `docs:` Canvis en documentació
- `style:` Format, estil (sense canvis de codi)
- `refactor:` Refactorització de codi
- `test:` Afegir o modificar tests

---

## 📝 Llicència

Aquest projecte és part del **Projecte Intermodular DAM** de BemenFP.

---

## 📞 Contacte

Per qualsevol dubte o suggeriment, contacta amb l'equip:

- Edim Batalla
- Marco Bia
- Daniel Caravaca

---

**Fet amb ❤️ per l'equip de CiMS - BemenFP 2026**
