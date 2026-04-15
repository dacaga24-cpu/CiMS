# Backend – CiMS

**Autors:** Edim Batalla, Marco Bia, Daniel Caravaca
**BemenFP – 2026**

## Objectiu

Aquest mòdul conté el frontend de **CiMS**, desenvolupat amb **Flutter**. La seva responsabilitat és gestionar la interfície d'usuari, la navegació de l'aplicació i la comunicació amb el backend mitjançant API.

El frontend **no accedeix directament a la base de dades**. Tota la informació s'obté a través del backend.

## Estructura actual

lib/
├── app/
│   ├── client/
│   │   └── api/
│   │       └── api_client_impl.dart
│   └── screen/
│       └── login/
│           ├── login.dart
│           └── login_controller.dart
├── core/
│   └── client/
│       └── api_client.dart
├── entity/
│   └── peak.dart
├── usecase/
│   └── get_peaks_usecase.dart
└── main.dart

## Flux bàsic de responsabilitats

La comunicació entre capes segueix aquesta idea general:

screen => controller => usecase => api client => backend

Això permet separar la interfície, la lògica d'aplicació i l'accés a dades.

## Criteris seguits

* Separació entre presentació i accés a dades.
* Comunicació amb el backend mitjançant API.
* Estructura senzilla i escalable.
* Organització coherent amb una futura ampliació per funcionalitats.