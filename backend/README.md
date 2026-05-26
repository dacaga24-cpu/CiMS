# Backend – CiMS

**Autors:** Edim Batalla, Marco Bia, Daniel Caravaca  
**BemenFP – 2026**

Aquest és el backend del projecte **CiMS**, una aplicació orientada al seguiment d’ascensions a cims de Catalunya.

El backend s’encarrega de rebre les peticions del frontend, validar les dades, aplicar la lògica de negoci, connectar amb la base de dades, gestionar l’autenticació i integrar serveis externs com Google Cloud Storage, SendGrid i Google Weather API.

## Funcionalitats principals

Aquest backend permet:

- registrar usuaris
- iniciar sessió amb JWT
- protegir rutes privades amb autenticació
- consultar i actualitzar el perfil de l’usuari
- canviar la contrasenya
- desactivar el compte d’usuari
- iniciar i completar el procés de recuperació de contrasenya
- enviar correus de recuperació amb SendGrid
- consultar el catàleg de cims
- filtrar cims per comarca, altitud, cerca i estat personal
- consultar cims per al mapa
- gestionar estats personals dels cims: completat, objectiu i favorit
- registrar ascensions manuals
- registrar ascensions verificades per geolocalització
- bloquejar la data de les ascensions verificades
- associar fotos a ascensions
- gestionar galeria de fotos d’ascensions
- gestionar foto de perfil
- pujar imatges mitjançant signed URLs de Google Cloud Storage
- consultar estadístiques personals
- consultar el dashboard principal
- calcular el repte mensual
- consultar previsió meteorològica diària i horària d’un cim
- limitar peticions sensibles amb rate limiters
- gestionar errors de manera centralitzada

## Tecnologies utilitzades

- Node.js
- Express
- MySQL
- JWT
- bcrypt
- SendGrid
- Google Cloud Storage
- Google Weather API
- Google Cloud Run
- Cloud SQL
- Firebase Hosting com a frontend web

## Estructura del projecte

El backend està organitzat per capes per separar responsabilitats:

```text
config/        Configuració de base de dades, GCS i comprovacions inicials
controllers/   Rep les peticions HTTP i retorna les respostes
middleware/    Autenticació, CORS, rate limiters i gestió d’errors
models/        Accés directe a la base de dades
routes/        Definició d’endpoints de l’API
services/      Lògica principal de negoci
utils/         Funcions auxiliars compartides
app.js         Configuració principal d’Express
server.js      Punt d’entrada del servidor
```

## Abans de començar

Cal tenir instal·lat:

- Node.js
- MySQL

També cal tenir creada la base de dades del projecte i configurar correctament les variables d’entorn.

## Instal·lació

Entra a la carpeta del backend i instal·la les dependències:

```bash
npm install
```

## Configuració del fitxer .env

Crea un fitxer `.env` a l’arrel del backend amb una configuració semblant a aquesta:

```env
# Server
PORT=3000
NODE_ENV=development

# Database - local
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=cims_db

# Database - Cloud SQL
INSTANCE_CONNECTION_NAME=your_project:your_region:your_instance

# JWT
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d

# Frontend / CORS
FRONTEND_URL=https://your-frontend-url.web.app
CORS_DEV_ORIGINS=http://localhost:8080,http://localhost:3000

# Password reset
APP_URL=http://localhost:3000

# Email - SendGrid
SENDGRID_API_KEY=your_sendgrid_api_key
MAIL_FROM=your_verified_sender@example.com

# Google Cloud Storage
GCS_BUCKET_NAME=your_private_bucket
PEAK_PHOTOS_BUCKET_NAME=your_public_peak_photos_bucket

# Local GCP credentials
GOOGLE_APPLICATION_CREDENTIALS=path/to/service-account.json

# Google Weather API
GOOGLE_WEATHER_API_KEY=your_google_weather_api_key
WEATHER_CACHE_TTL_MS=3600000

# Ascent verification
ASCENT_VERIFICATION_MAX_DISTANCE_METERS=500
ASCENT_VERIFICATION_MAX_ACCURACY_METERS=100
```

En producció, aquestes variables es configuren a Cloud Run. En local, es poden definir al fitxer `.env`.

## Com iniciar el servidor

Per iniciar el backend directament:

```bash
node server.js
```

Si el projecte disposa de scripts al `package.json`, també es pot iniciar amb:

```bash
npm start
```

o:

```bash
npm run dev
```

## Com saber si funciona

Si el servidor arrenca correctament, a la consola hauria d’aparèixer un missatge semblant a aquest:

```bash
Server running on port 3000
MySQL connection OK
```

També es pot comprovar amb la ruta:

```http
GET /health
```

Resposta esperada:

```json
{
  "status": "ok"
}
```

## Rutes principals de l’API

### Autenticació

```http
POST /api/auth/register
POST /api/auth/login
POST /api/auth/forgot-password
POST /api/auth/reset-password
GET  /api/auth/profile
```

### Usuaris

```http
GET    /api/users/profile
PUT    /api/users/profile
PUT    /api/users/password
DELETE /api/users/account
POST   /api/users/profile-photo/signed-upload-url
PUT    /api/users/profile-photo
DELETE /api/users/profile-photo
```

### Cims

```http
GET /api/peaks
GET /api/peaks/map
GET /api/peaks/:id
```

### Comarques

```http
GET /api/regions
```

### Estat personal dels cims

```http
GET    /api/peak-status
GET    /api/peak-status/:peakId
PUT    /api/peak-status/:peakId
DELETE /api/peak-status/:peakId
```

### Ascensions

```http
GET    /api/ascents
POST   /api/ascents
POST   /api/ascents/verified
GET    /api/ascents/peak/:peakId
PUT    /api/ascents/:ascentId
DELETE /api/ascents/:ascentId
GET    /api/ascents/:ascentId/photos
POST   /api/ascents/:ascentId/photos
```

### Fotos d’ascensions

```http
GET    /api/ascent-photos/me
POST   /api/ascent-photos/signed-upload-url
DELETE /api/ascent-photos/:photoId
```

### Estadístiques i dashboard

```http
GET /api/stats
GET /api/dashboard
GET /api/monthly-challenges/current
```

### Meteorologia

```http
GET /api/peaks/:peakId/weather/daily
GET /api/peaks/:peakId/weather/hourly?date=YYYY-MM-DD
```

## Autenticació

Les rutes privades utilitzen tokens JWT.

El client ha d’enviar el token a la capçalera:

```http
Authorization: Bearer <token>
```

Si el token no existeix, és invàlid o ha caducat, el backend retorna un error d’autenticació.

## Gestió d’imatges

Les imatges no es pugen directament al backend. El flux és:

1. El frontend demana una signed URL.
2. El backend genera una URL temporal de pujada a Google Cloud Storage.
3. El frontend puja la imatge directament al bucket.
4. El frontend confirma al backend el `storagePath`.
5. El backend valida que el fitxer existeix i el vincula al recurs corresponent.

Aquest flux s’utilitza per:

- fotos d’ascensions
- evidències d’ascensions verificades
- foto de perfil

## Verificació d’ascensions

El backend permet crear ascensions verificades amb la ubicació capturada pel dispositiu.

Perquè una ascensió sigui verificada, el backend comprova:

- que el cim existeixi
- que tingui coordenades vàlides
- que la ubicació capturada sigui vàlida
- que la precisió GPS sigui acceptable
- que la distància entre l’usuari i el cim estigui dins del límit configurat
- que hi hagi una foto d’evidència

Les ascensions verificades tenen la data bloquejada, ja que representa el moment real de la validació.

## Meteorologia

El backend integra Google Weather API per obtenir:

- previsió diària d’un cim
- previsió horària d’un cim

Les respostes es normalitzen abans d’arribar al frontend, de manera que la interfície no depèn directament del format de Google.

També existeix una cache en memòria per reduir crides repetides a la API externa i protegir la quota disponible.

## Seguretat

El backend inclou diferents mesures de seguretat:

- contrasenyes xifrades amb bcrypt
- autenticació amb JWT
- rutes privades protegides
- CORS restringit a orígens autoritzats
- capçaleres HTTP defensives amb Helmet
- limitació de mida del cos JSON
- rate limiters en endpoints sensibles
- tokens de recuperació amb caducitat
- tokens de recuperació guardats en format hash
- validació de propietat dels recursos
- validació de paths abans de vincular imatges
- gestió centralitzada d’errors

## Desplegament

El backend està preparat per desplegar-se a Google Cloud Run.

En producció, la connexió amb Cloud SQL es pot fer mitjançant:

```env
INSTANCE_CONNECTION_NAME=project:region:instance
```

Si aquesta variable existeix, el backend utilitza el socket de Cloud SQL. Si no existeix, utilitza `DB_HOST` i `DB_PORT`, pensat sobretot per a entorns locals.

## Notes finals

Aquest backend segueix una arquitectura per capes amb l’objectiu de mantenir el projecte ordenat, escalable i fàcil de mantenir. Els controladors gestionen les peticions, els serveis concentren la lògica de negoci, els models accedeixen a la base de dades i els middlewares resolen aspectes transversals com autenticació, seguretat, limitació de peticions i errors.
