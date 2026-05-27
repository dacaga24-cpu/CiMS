# CiMS

**Autors:** Edim Batalla, Marco Bia, Daniel Caravaca  
**Centre:** BemenFP  
**Cicle:** Desenvolupament d’Aplicacions Multiplataforma  
**Any:** 2026

## Descripció del projecte

**CiMS** és una aplicació híbrida de muntanya desenvolupada com a projecte final del cicle de Desenvolupament d’Aplicacions Multiplataforma. El projecte combina una aplicació mòbil i una versió web per oferir un catàleg de cims de Catalunya, permetre el registre d’ascensions i facilitar el seguiment personal del progrés de cada usuari.

La proposta neix de la necessitat de disposar d’una eina clara, centralitzada i especialitzada en cims. A diferència d’aplicacions més generalistes centrades en rutes o rendiment esportiu, CiMS posa el focus en el repte personal de descobrir, marcar, completar i recordar cims.

## Objectiu

L’objectiu principal de CiMS és oferir una plataforma senzilla i funcional perquè l’usuari pugui:

- consultar informació de cims de Catalunya;
- cercar i filtrar cims segons criteris útils;
- marcar cims com a assolits, objectius o favorits;
- registrar ascensions amb informació personal;
- consultar el seu historial i estadístiques;
- seguir el seu progrés des d’una interfície mòbil i web.

## Estat actual

El projecte es troba en fase final d’implementació, validació i preparació de lliurament. Les funcionalitats principals del MVP estan desenvolupades i integrades entre frontend, backend i base de dades. Durant la fase final també s’han incorporat funcionalitats de valor afegit, com la verificació d’ascensions per geolocalització, la visualització de mapes i la consulta de previsió meteorològica associada als cims.

## Funcionalitats principals

### Autenticació i usuari

- registre d’usuari;
- inici de sessió amb JWT;
- sessió protegida;
- recuperació de contrasenya;
- consulta i edició del perfil;
- canvi de contrasenya;
- tancament de sessió.

### Catàleg de cims

- llistat de cims de Catalunya;
- pantalla de detall del cim;
- cerca per nom;
- filtratge per comarca, altitud i estat personal;
- visualització de cims en mapa;
- consulta d’informació bàsica com altitud, localització i comarques associades.

### Gestió d’estat dels cims

Cada usuari pot gestionar l’estat personal de cada cim mitjançant tres marques independents:

- **assolit**;
- **objectiu**;
- **favorit**.

Aquesta informació permet personalitzar el catàleg i convertir-lo en una eina de planificació i seguiment.

### Registre d’ascensions

- registre d’una ascensió associada a un cim;
- data d’ascensió;
- notes personals;
- edició i eliminació d’ascensions pròpies;
- historial d’ascensions per cim;
- sincronització entre ascensions i estat del cim.

### Ascensions verificades

CiMS incorpora un flux de verificació d’ascensions mitjançant geolocalització. Aquesta funcionalitat permet comprovar si l’usuari es troba prop d’un cim abans de registrar una ascensió verificada i associar-hi una evidència fotogràfica.

### Estadístiques i dashboard

- resum de cims assolits;
- objectius actius;
- cims favorits;
- total d’ascensions;
- cims únics ascendits;
- metres acumulats;
- ascensions recents;
- evolució mensual;
- progrés del repte dels 100 cims;
- llistes de cims pendents i favorits.

### Meteorologia

La pantalla de detall del cim integra informació meteorològica per ajudar l’usuari a planificar millor les sortides. Es mostra previsió dels pròxims dies i informació per hores quan està disponible.

## Estructura del repositori

```text
CiMS/
├── frontend/   # Aplicació Flutter per a mòbil i web
├── backend/    # API REST amb Node.js i Express
├── database/   # Scripts SQL, estructura i dades inicials
└── README.md   # Documentació general del projecte
```

Cada part del projecte disposa de documentació específica pròpia:

- `frontend/README.md`
- `backend/README.md`
- `database/README.md`

## Arquitectura general

CiMS segueix una arquitectura separada per responsabilitats.

### Frontend

El frontend està desenvolupat amb Flutter i segueix una organització per capes:

```text
screen → controller → use case → api client → backend
```

Aquesta estructura permet separar la interfície d’usuari, l’estat de pantalla, la lògica d’aplicació i la comunicació amb l’API.

### Backend

El backend està desenvolupat amb Node.js i Express seguint una arquitectura modular:

```text
routes → controllers → services → models
```

Aquesta separació facilita la mantenibilitat, la validació de dades, la protecció de rutes i l’evolució del sistema.

### Base de dades

La base de dades utilitza MySQL i manté un model relacional orientat a les entitats principals del projecte:

- usuaris;
- cims;
- comarques;
- relacions entre cims i comarques;
- ascensions;
- estats personals dels cims;
- fotos d’ascensions;
- tokens de recuperació de contrasenya.

## Tecnologies utilitzades

### Frontend

- Flutter
- Dart
- AutoRoute
- Google Maps
- Gestió modular per pantalles, controllers, use cases i clients d’API

### Backend

- Node.js
- Express
- JWT
- bcrypt
- SendGrid
- Helmet
- CORS
- Rate limiting

### Base de dades

- MySQL
- SQL
- Claus primàries i foranes
- Índexs
- Seeds de dades inicials

### Desplegament i eines

- Firebase Hosting
- Google Cloud Run
- Google Cloud SQL
- GitHub
- Jira
- Confluence
- Figma
- Miro

## Requisits previs

Per executar el projecte en local cal tenir instal·lat:

- Flutter SDK;
- Dart;
- Node.js;
- npm;
- MySQL;
- Git;
- un navegador compatible per a la versió web;
- Android Studio o Xcode si es vol executar en dispositius mòbils o emuladors.

## Configuració general

### Backend

El backend necessita un fitxer d’entorn amb les variables de configuració principals:

```env
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_USER=...
DB_PASSWORD=...
DB_NAME=cims_db
JWT_SECRET=...
FRONTEND_URL=...
APP_URL=...
SENDGRID_API_KEY=...
```

En entorns desplegats també es poden utilitzar variables específiques per a Cloud SQL, CORS i serveis externs.

### Frontend

El frontend pot rebre la URL del backend mitjançant `dart-define`:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Per a builds web o entorns desplegats, aquesta URL ha d’apuntar al backend publicat.

## Execució en local

### 1. Clonar el repositori

```bash
git clone <url-del-repositori>
cd CiMS
```

### 2. Preparar la base de dades

```bash
cd database
```

Executar els scripts SQL corresponents per crear l’estructura i carregar les dades inicials segons la documentació del directori `database/`.

### 3. Executar el backend

```bash
cd backend
npm install
npm run dev
```

### 4. Executar el frontend

```bash
cd frontend
flutter pub get
flutter run
```

Per executar la versió web:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

## Desplegament

El projecte està preparat per funcionar amb:

- backend desplegat a Google Cloud Run;
- base de dades allotjada a Google Cloud SQL;
- frontend web publicat a Firebase Hosting.

Aquesta separació permet mantenir una arquitectura propera a un entorn real de producció, amb frontend, backend i base de dades desacoblats.

## Seguretat

El projecte incorpora criteris bàsics de seguretat:

- contrasenyes emmagatzemades amb hash;
- autenticació mitjançant JWT;
- rutes protegides al backend;
- validació d’entrada de dades;
- CORS restringit segons origen;
- Helmet per reforçar capçaleres HTTP;
- limitació de mida del cos de les peticions;
- rate limiting en endpoints sensibles;
- tokens de recuperació de contrasenya d’un sol ús i amb caducitat.

## Gestió del projecte

El desenvolupament s’ha organitzat amb metodologia iterativa i seguiment per sprints. Les eines principals de gestió i documentació han estat:

- **Jira** per a tasques, bugs, epics i seguiment del backlog;
- **Confluence** per a documentació tècnica, informes de sprint i decisions del projecte;
- **Figma** per al disseny d’interfície;
- **Miro** per a diagrames, fluxos i arquitectura;
- **GitHub** per al control de versions i revisió de canvis.

## Abast del projecte

El projecte cobreix el nucli funcional previst per al MVP i incorpora algunes funcionalitats addicionals de valor real. L’abast actual inclou consulta de cims, registre d’ascensions, seguiment de progrés, mapa, perfil, estadístiques, verificació per geolocalització i meteorologia.

Algunes possibles línies futures serien:

- sistema complet de gamificació;
- rànquings i reptes avançats;
- integració amb fitxers GPX;
- navegació offline;
- autenticació amb proveïdors externs;
- sistema social o comunitari;
- notificacions i alertes personalitzades.

## Notes finals

CiMS és un projecte acadèmic amb una orientació pràctica i professional. El seu objectiu no és només implementar funcionalitats, sinó demostrar una arquitectura coherent, una separació clara de responsabilitats, una base de dades relacional ben estructurada i una experiència d’usuari útil per a persones interessades en la muntanya.
