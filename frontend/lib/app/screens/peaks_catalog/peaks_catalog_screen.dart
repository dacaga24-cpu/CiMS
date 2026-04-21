import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'peaks_catalog_controller.dart';
import 'widgets/peak_detail_card.dart';
import 'widgets/peaks_search_bar.dart';

// Aquesta pantalla mostra el catàleg de cims de l’aplicació.
// La seva funció és construir la vista general del llistat i connectar-la
// amb el controller, que és qui gestiona l’estat i les dades.
@RoutePage()
class PeaksCatalogScreen extends StatefulWidget {
  const PeaksCatalogScreen({super.key});

  @override
  State<PeaksCatalogScreen> createState() => _PeaksCatalogScreenState();
}

// Aquesta classe gestiona el comportament intern de la pantalla del catàleg.
// S’encarrega de preparar el controller, escoltar-ne els canvis
// i construir la interfície segons l’estat actual de les dades.
class _PeaksCatalogScreenState extends State<PeaksCatalogScreen> {
  // Aquest controlador concentra les dades i l’estat del catàleg,
  // incloent la càrrega inicial i la cerca de cims.
  late final PeaksCatalogController controller;

  // Aquest mètode prepara el controller quan la pantalla es crea
  // i inicia la càrrega inicial de les dades que es mostraran al catàleg.
  @override
  void initState() {
    super.initState();
    controller = PeaksCatalogController()..initialize();
  }

  // Aquest mètode allibera els recursos associats al controller
  // quan la pantalla deixa d’existir.
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Aquest mètode construeix la interfície de la pantalla i la reactualitza
  // quan canvia l’estat del controller.
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Aquest bloc mostra la barra de cerca del catàleg.
                // De moment també deixa preparat l’accés al botó de filtres
                // per a futures iteracions.
                PeaksSearchBar(
                  controller: controller.searchController,
                  onChanged: controller.onSearchChanged,
                  onFilterTap: () {},
                ),
                const SizedBox(height: 18),

                // Aquest espai principal mostra un indicador de càrrega
                // mentre s’obtenen les dades i, quan ja estan disponibles,
                // presenta la llista de cims del catàleg.
                Expanded(
                  child: controller.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: controller.peaks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            // Aquest bloc recupera el cim corresponent a cada posició
                            // i el converteix en una targeta visual del llistat.
                            final peak = controller.peaks[index];

                            return PeakDetailCard(
                              peak: peak,
                              onTap: () {},
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}