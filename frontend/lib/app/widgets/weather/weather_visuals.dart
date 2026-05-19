import 'package:cims/core/entity/weather_condition.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

// Aquest fitxer concentra els recursos visuals associats a cada categoria
// meteorològica normalitzada. La card del detall i els chips del filtre
// han de pintar la mateixa icona i el mateix color per a una mateixa
// condició, perquè sinó l'usuari hauria d'aprendre dues paletes
// diferents per al mateix concepte.

// Color groc fix del sol. Es manté constant independentment del context
// (accent de la card, color del cel) perquè un sol gris es llegeix com
// una nuvolada qualsevol; el groc és el que el fa identificable a primer
// cop d'ull.
const Color _weatherSunColor = Color(0xFFF59E0B);

// Color "moonlight" per a la lluna. Lleugerament blau-gris fred per
// transmetre "nit" enfront del càlid groc solar. Manté contrast amb el
// núvol gris més fosc en les composicions de nit nuvolosa.
const Color _weatherMoonColor = Color(0xFFCBD5E1);

// Aquest mètode retorna el widget que pinta la icona meteorològica
// d'una categoria, ajustada al context dia/nit i amb colors coherents.
// Es retorna un Widget (no un IconData) perquè la condició "variable"
// és una composició de sol/lluna + núvol amb colors diferents, i això
// només es pot expressar amb un Stack de dues icones.
//
// El paràmetre `color` només afecta a la part neutra (núvol, pluja,
// neu, boira...). El sol manté sempre el groc i la lluna el seu color
// "moonlight", independentment del que arribi com a accent, perquè
// la lectura visual no s'enfonsi.
//
// `isDaytime` només té efecte en categories que canvien d'aspecte
// entre dia i nit: sunny (sol ↔ lluna) i partlyCloudy (sol + núvol ↔
// lluna + núvol). Per a pluja, neu, boira i nuvolós el dibuix és el
// mateix de dia i de nit perquè el fenomen es percep igual.
Widget weatherIconWidget(
  WeatherConditionType type, {
  required double size,
  required Color color,
  bool isDaytime = true,
}) {
  switch (type) {
    case WeatherConditionType.sunny:
      return Icon(
        isDaytime ? Symbols.sunny : Symbols.bedtime,
        size: size,
        color: isDaytime ? _weatherSunColor : _weatherMoonColor,
      );
    case WeatherConditionType.partlyCloudy:
      return _PartlyCloudyIcon(
        size: size,
        cloudColor: color,
        isDaytime: isDaytime,
      );
    case WeatherConditionType.cloudy:
      return Icon(Symbols.cloudy, size: size, color: color);
    case WeatherConditionType.rainy:
      // Núvol amb gotes caient, equivalent al que hauríem hagut de
      // muntar amb un Stack(cloud + drop) si no tinguéssim Material
      // Symbols al projecte.
      return Icon(Symbols.rainy, size: size, color: color);
    case WeatherConditionType.snowy:
      // ac_unit és el floc de neu individual; combina bé amb la idea
      // de "copo de nieve" sense ambigüitat. Material Symbols també
      // ofereix Symbols.snowing (núvol + flocs) si en un futur es
      // vol diferenciar nevada lleugera de neu intensa.
      return Icon(Symbols.ac_unit, size: size, color: color);
    case WeatherConditionType.foggy:
      return Icon(Symbols.foggy, size: size, color: color);
    case WeatherConditionType.unknown:
      return Icon(Symbols.help_outline, size: size, color: color);
  }
}

// Aquest widget composa l'aspecte "sol + núvol" (o "lluna + núvol") amb
// dues icones de Material Symbols apilades. No es fa servir l'icona
// nativa Symbols.partly_cloudy_day perquè és una sola glifa i no permet
// pintar el sol d'un color diferent del núvol; pintar-ho tot del mateix
// gris feia perdre l'efecte visual d'"hi ha sol darrere d'un núvol".
class _PartlyCloudyIcon extends StatelessWidget {
  const _PartlyCloudyIcon({
    required this.size,
    required this.cloudColor,
    required this.isDaytime,
  });

  // Mida total de la composició, equivalent a la mida d'una icona
  // simple. Els dos elements interns s'escalen relativament.
  final double size;

  // Color del núvol. El sol o la lluna usen sempre els seus colors
  // propis (_weatherSunColor / _weatherMoonColor).
  final Color cloudColor;

  // Determina si es pinta sol (dia) o lluna (nit) com a element
  // celestial darrere del núvol.
  final bool isDaytime;

  @override
  Widget build(BuildContext context) {
    final celestialIcon = isDaytime ? Symbols.sunny : Symbols.bedtime;
    final celestialColor = isDaytime ? _weatherSunColor : _weatherMoonColor;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // El sol o la lluna queden darrere, a la cantonada superior
          // dreta, per simular el clàssic "astre que s'amaga
          // parcialment darrere d'un núvol".
          Positioned(
            top: 0,
            right: 0,
            child: Icon(
              celestialIcon,
              size: size * 0.62,
              color: celestialColor,
            ),
          ),
          // El núvol va davant, a la cantonada inferior esquerra, i
          // tapa parcialment l'astre.
          Positioned(
            bottom: 0,
            left: 0,
            child: Icon(
              Symbols.cloud,
              size: size * 0.78,
              color: cloudColor,
            ),
          ),
        ],
      ),
    );
  }
}

// Aquest mètode retorna el color d'accent que correspon a cada
// condició normalitzada. Es manté alineat amb weatherIconFor perquè
// quan algun cop calgui canviar la paleta es modifiqui en un únic lloc.
Color weatherAccentColorFor(WeatherConditionType type) {
  switch (type) {
    case WeatherConditionType.sunny:
      return const Color(0xFFF59E0B);
    case WeatherConditionType.partlyCloudy:
      // Gris més clar que el cobert per transmetre "nuvolós però amb
      // sol". El contrast cromàtic és el principal indicador visual.
      return const Color(0xFF9CA3AF);
    case WeatherConditionType.cloudy:
      // Gris més fosc per transmetre "cel cobert".
      return const Color(0xFF4B5563);
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

// Aquest enum classifica la intensitat del vent en tres nivells útils
// per a planificació excursionista. Es manté ortogonal al tipus de
// condició meteorològica (sol, pluja, neu…) perquè el vent és un
// modificador que es pot combinar amb qualsevol d'aquestes.
enum WindSeverity {
  // Vent calm o moderat (< 20 km/h sostingut). La UI no destaca res.
  calm,

  // Vent fort (20-40 km/h sostingut o ràfegues de 40-60 km/h). Indicació
  // discreta perquè l'usuari sàpiga que pot ser incòmode en cresta.
  moderate,

  // Vent molt fort (≥ 40 km/h sostingut o ràfegues ≥ 60 km/h).
  // Indicació destacada — pot ser perillós a la muntanya.
  strong,
}

// Aquesta extensió aporta etiquetes natives als nivells de vent perquè
// la UI no hagi de duplicar les cadenes en cada widget consumidor.
extension WindSeverityLabels on WindSeverity {
  // Indica si el nivell mereix ser pintat a la UI. La intensitat calma
  // (per defecte la majoria de dies) no necessita cap badge.
  bool get shouldHighlight => this != WindSeverity.calm;

  // Etiqueta llarga, pensada per a missatges complets (avisos, tooltips,
  // resum de filtres). No s'utilitza dins de la pílula del carrusel
  // diari perquè "Vent molt fort" no hi cap; per a aquest cas hi ha
  // shortLabel.
  String get displayLabel {
    switch (this) {
      case WindSeverity.calm:
        return 'Calm';
      case WindSeverity.moderate:
        return 'Vent fort';
      case WindSeverity.strong:
        return 'Vent molt fort';
    }
  }

  // Etiqueta curta per a espais reduïts (la pílula del carrusel diari
  // té només 62 px d'amplada interior). S'omet la paraula "Vent" perquè
  // la icona ja transmet de què parlem; el text indica només la
  // intensitat.
  String get shortLabel {
    switch (this) {
      case WindSeverity.calm:
        return '';
      case WindSeverity.moderate:
        return 'Fort';
      case WindSeverity.strong:
        return 'Molt fort';
    }
  }
}

// Aquest mètode classifica el vent a partir de la velocitat sostinguda
// (km/h) i la ràfega màxima. Es prenen tots dos valors perquè un dia
// "tranquil de mitjana" amb ràfegues puntuals fortes és perillós
// igualment per a una excursió, sobretot en crestes; mirar només la
// mitjana l'amagaria. Els llindars són una referència informativa
// pensada per a alta muntanya, no avisos oficials.
WindSeverity windSeverityFor({double? speedKmh, double? gustKmh}) {
  final speed = speedKmh ?? 0;
  final gust = gustKmh ?? 0;
  if (speed >= 40 || gust >= 60) {
    return WindSeverity.strong;
  }
  if (speed >= 20 || gust >= 40) {
    return WindSeverity.moderate;
  }
  return WindSeverity.calm;
}

// Aquest mètode retorna el color que ha d'usar el badge de vent a la
// UI segons el nivell de severitat. Es manté en un únic lloc perquè la
// card diària, el panell horari i qualsevol futur consumidor pintin
// exactament el mateix codi cromàtic per a la mateixa intensitat.
Color windSeverityColor(WindSeverity severity) {
  switch (severity) {
    case WindSeverity.calm:
      return const Color(0xFF6B7280);
    case WindSeverity.moderate:
      return const Color(0xFFD97706);
    case WindSeverity.strong:
      return const Color(0xFFDC2626);
  }
}
