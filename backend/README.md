# Backend API - CiMS (Rutas de Muntanya)

API REST construïda amb Node.js, Express i MySQL per a l'aplicació CiMS.

## 📋 Requisits

- Node.js (v14 o superior)
- MySQL (v5.7 o superior)
- npm o yarn

## 🚀 Instal·lació

### 1. Instal·lar dependències

```bash
cd backend
npm install
```

### 2. Configurar variables d'entorn

Copia `.env.example` a `.env` i modifica les credencials:

```bash
cp .env.example .env
```

Edita `.env`:

```env
PORT=3000
NODE_ENV=development

DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=la_teva_contrasenya
DB_NAME=cims_db

JWT_SECRET=la_teva_clau_secreta_super_segura
JWT_EXPIRES_IN=7d

CORS_ORIGIN=http://localhost:8080,http://localhost:3000
```

### 3. Crear les taules necessàries

Executa aquest SQL a MySQL Workbench o des de la terminal:

```sql
-- La taula mountain_routes ja existeix del script anterior

-- Crear taula d'ascensions
CREATE TABLE IF NOT EXISTS ascensions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  route_id INT NOT NULL,
  data_ascensio DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (route_id) REFERENCES mountain_routes(id) ON DELETE CASCADE
);

-- Crear taula d'estats de rutes
CREATE TABLE IF NOT EXISTS route_states (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  route_id INT NOT NULL,
  estat VARCHAR(50) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (route_id) REFERENCES mountain_routes(id) ON DELETE CASCADE,
  UNIQUE KEY unique_user_route (user_id, route_id)
);
```

O executa el script proporcionat:

```bash
mysql -u root -p cims_db < database/backend_tables.sql
```

### 4. Iniciar el servidor

**Mode desenvolupament (amb auto-reload):**

```bash
npm run dev
```

**Mode producció:**

```bash
npm start
```

El servidor s'iniciarà a `http://localhost:3000`

## 📚 Endpoints de l'API

### Autenticació (`/api/auth`)

| Mètode | Endpoint | Descripció | Auth |
|--------|----------|------------|------|
| POST | `/api/auth/register` | Registrar nou usuari | ❌ |
| POST | `/api/auth/login` | Iniciar sessió | ❌ |
| GET | `/api/auth/profile` | Obtenir perfil | ✅ |
| GET | `/api/auth/verify` | Verificar token | ✅ |

### Cims/Rutas (`/api/cims`)

| Mètode | Endpoint | Descripció | Auth |
|--------|----------|------------|------|
| GET | `/api/cims` | Obtenir tots els cims | ❌ |
| GET | `/api/cims?difficulty=media` | Filtrar per dificultat | ❌ |
| GET | `/api/cims?search=montseny` | Cercar per nom | ❌ |
| GET | `/api/cims/stats` | Estadístiques | ❌ |
| GET | `/api/cims/:id` | Obtenir cim per ID | ❌ |
| POST | `/api/cims` | Crear nou cim | ✅ |
| PUT | `/api/cims/:id` | Actualitzar cim | ✅ |
| DELETE | `/api/cims/:id` | Eliminar cim | ✅ |

### Ascensions (`/api/ascensions`)

| Mètode | Endpoint | Descripció | Auth |
|--------|----------|------------|------|
| GET | `/api/ascensions` | Les meves ascensions | ✅ |
| GET | `/api/ascensions/stats` | Les meves estadístiques | ✅ |
| GET | `/api/ascensions/route/:id` | Ascensions d'una ruta | ✅ |
| GET | `/api/ascensions/:id` | Obtenir ascensió per ID | ✅ |
| POST | `/api/ascensions` | Crear ascensió | ✅ |
| PUT | `/api/ascensions/:id` | Actualitzar ascensió | ✅ |
| DELETE | `/api/ascensions/:id` | Eliminar ascensió | ✅ |

### Estats (`/api/estats`)

| Mètode | Endpoint | Descripció | Auth |
|--------|----------|------------|------|
| GET | `/api/estats` | Els meus estats | ✅ |
| GET | `/api/estats?estat=favorit` | Filtrar per estat | ✅ |
| GET | `/api/estats/stats` | Estadístiques | ✅ |
| GET | `/api/estats/favorites` | Favorits | ✅ |
| GET | `/api/estats/completed` | Completats | ✅ |
| GET | `/api/estats/planned` | Planificats | ✅ |
| GET | `/api/estats/route/:id` | Estat d'una ruta | ✅ |
| POST | `/api/estats` | Crear/actualitzar estat | ✅ |
| POST | `/api/estats/favorite/:id` | Toggle favorit | ✅ |
| DELETE | `/api/estats/route/:id` | Eliminar estat | ✅ |

## 🔐 Autenticació

L'API utilitza JWT (JSON Web Tokens) per a l'autenticació.

### Registre

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "joan",
    "email": "joan@example.com",
    "password": "password123"
  }'
```

### Login

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "joan@example.com",
    "password": "password123"
  }'
```

Resposta:

```json
{
  "message": "Inici de sessió correcte",
  "user": {
    "id": 1,
    "username": "joan",
    "email": "joan@example.com"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### Usar el token

Afegeix el token a les peticions que requereixin autenticació:

```bash
curl -X GET http://localhost:3000/api/ascensions \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

## 📝 Exemples d'ús

### Obtenir tots els cims

```bash
curl http://localhost:3000/api/cims
```

### Crear una ascensió

```bash
curl -X POST http://localhost:3000/api/ascensions \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "route_id": 1,
    "data_ascensio": "2024-03-31",
    "notes": "Gran dia per fer aquesta ruta!"
  }'
```

### Afegir a favorits

```bash
curl -X POST http://localhost:3000/api/estats/favorite/1 \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## 🧪 Provar amb Postman

1. Importa la col·lecció de Postman (si està disponible)
2. Configura la variable `baseUrl` a `http://localhost:3000`
3. Registra't i guarda el token
4. Usa el token per a les peticions autenticades

## 📂 Estructura del projecte

```
backend/
├── src/
│   ├── config/
│   │   └── db.js              # Connexió a MySQL
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── cimController.js
│   │   ├── ascensioController.js
│   │   └── estatController.js
│   ├── middleware/
│   │   ├── auth.js            # Verificació JWT
│   │   └── errorHandler.js
│   ├── models/
│   │   ├── usuariModel.js
│   │   ├── cimModel.js
│   │   ├── ascensioModel.js
│   │   └── estatCimModel.js
│   ├── routes/
│   │   ├── auth.routes.js
│   │   ├── cims.routes.js
│   │   ├── ascensions.routes.js
│   │   └── estats.routes.js
│   └── app.js                 # Configuració Express
├── .env                       # Variables d'entorn
├── .env.example
├── package.json
└── server.js                  # Punt d'entrada
```

## 🐛 Depuració

Activa el mode desenvolupament per veure logs detallats:

```bash
NODE_ENV=development npm run dev
```

## 🔒 Seguretat

- Canvia `JWT_SECRET` en producció
- Usa HTTPS en producció
- Configura CORS adequadament
- No pujar el fitxer `.env` al repositori

## 📄 Llicència

Aquest projecte és part del Projecte Intermodular DAM.
