import 'package:cims/core/entity/weather_condition.dart';
import 'package:flutter/material.dart';

// Aquest fitxer concentra els recursos visuals associats a cada categoria
// meteorològica normalitzada. La card del detall i els chips del filtre
// han de pintar la mateixa icona i el mateix color per a una mateixa
// condició, perquè sinó l'usuari hauria d'aprendre dues paletes
// diferents per al mateix concepte.

// Aquest mètode tradueix una categoria normalitzada en la icona Material
// que la representa millor. Es manté com a funció top-level perquè és
// pura presentació, sense estat, i qualsevol widget pot reaprofitar-la
// sense haver d'importar un controller o un manager.
IconData weatherIconFor(WeatherConditionType type) {
  switch (type) {
    case WeatherConditionType.sunny:
      return Icons.wb_sunny_rounded;
    case WeatherConditionType.cloudy:
      return Icons.cloud_rounded;
    case WeatherConditionType.rainy:
      return Icons.water_drop_rounded;
    case WeatherConditionType.snowy:
      return Icons.ac_unit_rounded;
    case WeatherConditionType.foggy:
      return Icons.blur_on_rounded;
    case WeatherConditionType.unknown:
      return Icons.help_outline_rounded;
  }
}

// Aquest mètode retorna el color d'accent que correspon a cada
// condició normalitzada. Es manté alineat amb weatherIconFor perquè
// quan algun cop calgui canviar la paleta es modifiqui en un únic lloc.
Color weatherAccentColorFor(WeatherConditionType type) {
  switch (type) {
    case WeatherConditionType.sunny:
      return const Color(0xFFF59E0B);
    case WeatherConditionType.cloudy:
      return const Color(0xFF6B7280);
    case WeatherConditionType.rainy:
      return const Color(0xFF2563EB);
    case WeatherConditionType.snowy:
      return const Color(0xFF7DD3FC);
    case WeatherConditionType.foggy:
      return const Color(0xFF94A3B8);
    case WeatherConditionType.unknown:
      return const Color(0xFFCBD5E1);
  }
}
