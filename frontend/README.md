# Frontend – CiMS

**Autors:** Edim Batalla, Marco Bia, Daniel Caravaca  
**BemenFP – 2026**

## Objectiu

Aquest mòdul conté el frontend de **CiMS**, desenvolupat amb **Flutter**. La seva responsabilitat és gestionar la interfície d'usuari, la navegació de l'aplicació i la comunicació amb el backend mitjançant API.

El frontend **no accedeix directament a la base de dades**. Tota la informació s'obté a través del backend.

## Flux bàsic de responsabilitats

La comunicació entre capes segueix aquesta idea general:

`screen => controller => usecase => api client => backend`

Això permet separar la interfície, la lògica d'aplicació i l'accés a dades.

## Criteris seguits

- Separació entre presentació i accés a dades.
- Comunicació amb el backend mitjançant API.
- Estructura senzilla i escalable.
- Organització coherent amb una futura ampliació per funcionalitats.

## Desplegament web del frontend

La versió web del frontend es publica de manera independent del backend.  
En el nostre cas, el backend està desplegat a Google Cloud Run i el frontend web es pot publicar a **Firebase Hosting**.

Abans de desplegar, cal assegurar que la configuració del frontend apunta a la URL pública del backend.

Exemple de backend desplegat:

`https://cims-backend-639822259289.europe-southwest1.run.app/`

## Preparació prèvia

Abans del primer desplegament, cal tenir instal·lats:

- **Flutter**
- **Node.js**
- **Firebase CLI**

Instal·lació de Firebase CLI:

```bash
npm install -g firebase-tools
```

Després, cal iniciar sessió a Firebase:

```bash
firebase login
```

## Build de la web

Per generar la versió web preparada per producció:

```bash
flutter build web
```

Aquesta comanda genera els fitxers estàtics dins de:

```bash
build/web
```

## Primer desplegament a Firebase Hosting

Des de l'arrel del projecte, inicialitza el hosting:

```bash
firebase init hosting
```

Durant la configuració:
- selecciona el projecte de Firebase corresponent
- indica build/web com a directori públic
- respon yes si et pregunta si és una single-page app
- si et pregunta si vols sobreescriure fitxers existents, revisa-ho abans d’acceptar

Un cop configurat, desplega la web amb:

```bash
firebase deploy
```

Quan acabi, Firebase retornarà una URL pública.

## Actualitzar el contingut del frontend a la web

Cada vegada que es faci un canvi al frontend i es vulgui publicar online, el procés és:
- Actualitzar el codi del frontend
- Tornar a generar la build web
- Tornar a desplegar a Firebase Hosting

Comandes habituals:

```bash
flutter build web
firebase deploy
```

## Resum del flux de publicació

Flux habitual de publicació del frontend web:

Modificar frontend -> flutter build web -> firebase deploy