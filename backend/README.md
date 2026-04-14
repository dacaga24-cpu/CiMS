# Backend – CiMS

**Autors:** Edim Batalla, Marco Bia, Daniel Caravaca
**BemenFP – 2026**

Aquest és el backend del projecte **CiMS**.

S’encarrega de gestionar la part interna de l’aplicació: rebre peticions del frontend, validar dades, connectar amb la base de dades i retornar respostes.

## Què fa aquest backend

De manera resumida, aquest backend permet:

- registrar usuaris
- iniciar sessió
- protegir rutes amb autenticació
- consultar el perfil d’un usuari autenticat
- iniciar el procés de recuperació de contrasenya
- restablir la contrasenya amb token
- connectar amb la base de dades MySQL

## Tecnologies utilitzades

- Node.js
- Express
- MySQL
- JWT
- bcrypt

## Abans de començar

Cal tenir instal·lat:

- Node.js
- MySQL

També cal tenir creada la base de dades `cims_db` i configurar correctament el fitxer `.env`.

## Instal·lació

Entra a la carpeta del backend i instal·la les dependències:

```bash
npm install
```

## Configuració del fitxer .env

Crea un fitxer .env a l’arrel del backend amb una configuració semblant a aquesta:

# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=cims_db

# Server
PORT=3000
NODE_ENV=development

# JWT
JWT_SECRET=your_jwt_secret
JWT_EXPIRES_IN=7d

## Com iniciar el servidor

Si el projecte s’inicia directament des del fitxer principal:

```bash
node server.js
```

Si més endavant hi ha scripts definits al package.json, també es podria iniciar amb alguna comanda com:

```bash
npm start
```

o:
```bash
npm run dev
```

## Com saber si funciona

Si el servidor arrenca bé, a la consola hauria d’aparèixer un missatge semblant a aquest:

```bash
Server running on port 3000
MySQL connection OK
```

També es pot comprovar amb la ruta següent:

```bash
GET /health
```

La resposta esperada és:

```bash
{
  "status": "ok"
}
```

## Estructura bàsica

El backend està organitzat per capes per separar responsabilitats:

routes/ defineix les rutes
controllers/ rep les peticions i prepara la resposta
services/ conté la lògica principal
models/ accedeix a la base de dades
middleware/ gestiona autenticació i errors
config/ conté la configuració de connexió i comprovacions inicials

# Autors:

Edim Batalla
Marco Bia
Daniel Caravaca

BemenFP - 2026
