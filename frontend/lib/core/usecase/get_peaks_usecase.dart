import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/region.dart';

// Aquest cas d'ús encapsula l'obtenció del catàleg de cims.
// De moment retorna dades locals de mostra perquè la pantalla es pugui
// construir i validar visualment abans de connectar-la amb l'API.
class GetPeaksUseCase {
  const GetPeaksUseCase();

  // Aquest mètode retorna la col·lecció base de cims que la pantalla utilitza
  // durant aquesta primera iteració de disseny.
  Future<List<Peak>> execute() async {
    // Aquest conjunt de dades simula el catàleg inicial de cims
    // mentre encara no s'ha connectat la recuperació real des del backend.
    // Els identificadors de les comarques són de mostra i es correspondran
    // amb els reals quan s'alimenti la llista des de l'API.
    return const [
      Peak(
        id: 1,
        name: 'Pica d\'Estats',
        altitude: 3143,
        regions: [Region(id: 1, name: 'Pallars Sobirà')],
      ),
      Peak(
        id: 2,
        name: 'Pedraforca',
        altitude: 2506,
        regions: [Region(id: 2, name: 'Berguedà')],
      ),
      Peak(
        id: 3,
        name: 'Puigmal',
        altitude: 2913,
        regions: [Region(id: 3, name: 'Ripollès')],
      ),
      Peak(
        id: 4,
        name: 'Canigó',
        altitude: 2784,
        regions: [Region(id: 4, name: 'Conflent')],
      ),
      Peak(
        id: 5,
        name: 'Turó de l\'Home',
        altitude: 1706,
        regions: [Region(id: 5, name: 'Vallès Oriental')],
      ),
      Peak(
        id: 6,
        name: 'Carlit',
        altitude: 2921,
        regions: [Region(id: 6, name: 'Alta Cerdanya')],
      ),
      Peak(
        id: 7,
        name: 'Tossa Plana de Lles',
        altitude: 2916,
        regions: [
          Region(id: 7, name: 'Baixa Cerdanya'),
          Region(id: 8, name: 'Alt Urgell'),
        ],
      ),
      Peak(
        id: 8,
        name: 'Bastiments',
        altitude: 2883,
        regions: [
          Region(id: 3, name: 'Ripollès'),
          Region(id: 4, name: 'Conflent'),
        ],
      ),
    ];
  }
}
