import 'package:cims/app/widgets/weather/weather_visuals.dart';
import 'package:cims/core/entity/peak_hourly_weather.dart';
import 'package:cims/core/entity/peak_weather.dart';
import 'package:cims/core/entity/weather_condition.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

// Aquest widget mostra la previsió meteorològica del cim en forma de
// targeta. Combina un carrusel de fins a 7 dies i un panell horari que
// es desplega quan l'usuari toca una de les píldores. La pantalla de
// detall passa l'estat i les accions perquè la card pugui pintar tots
// els casos (càrrega, error, dades) sense conèixer cap controller.

class PeakDetailWeatherCard extends StatelessWidget {
  const PeakDetailWeatherCard({
    super.key,
    required this.forecast,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetryTap,
    required this.expandedDay,
    required this.expandedHourly,
    required this.isExpandedHourlyLoading,
    required this.expandedHourlyError,
    required this.onDayTap,
    required this.onHourlyRetryTap,
  });

  // Aquesta propietat rep la previsió ja descodificada o null mentre
  // encara s'està carregant per primera vegada.
  final PeakWeather? forecast;

  // Aquesta propietat indica si la càrrega està en curs. La card mostra un
  // estat esquelet (skeleton) quan és true i no hi ha encara previsió en
  // memòria, per evitar parpellejos durant els reintentaments.
  final bool isLoading;

  // Aquesta propietat porta el missatge d'error quan la càrrega falla.
  // Quan està informat i no hi ha previsió, la card mostra un missatge
  // d'error específic amb un botó per tornar-ho a provar.
  final String? errorMessage;

  // Aquesta acció es dispara quan l'usuari prem el botó de reintentar
  // la previsió diària.
  final Future<void> Function() onRetryTap;

  // Aquesta propietat indica quina data té el panell horari obert (o
  // null si no n'hi ha cap). Permet pintar la píldora corresponent amb
  // accent ressaltat sense haver de comparar dates al widget.
  final String? expandedDay;

  // Aquesta propietat porta la previsió horària del dia expandit. Si
  // arriba null vol dir que encara no hi ha dades cachejades per a
  // aquest dia; el panell decideix entre mostrar skeleton, error o
  // contingut a partir dels altres paràmetres.
  final PeakHourlyWeather? expandedHourly;

  // Indica si el panell horari del dia expandit està descarregant
  // dades en aquest moment. Es manté independent de isLoading perquè
  // l'usuari pot demanar hores d'un dia mentre la previsió diària ja
  // està carregada.
  final bool isExpandedHourlyLoading;

  // Missatge d'error específic del panell horari obert. Si està
  // informat i no hi ha hores cachejades, el panell mostra el missatge
  // amb un botó per reintentar el dia concret.
  final String? expandedHourlyError;

  // Aquesta acció es dispara quan l'usuari toca una píldora del
  // carrusel diari. El controller decideix si expandir, col·lapsar o
  // canviar el dia obert.
  final void Function(String date) onDayTap;

  // Aquesta acció es dispara des del botó de reintentar del panell
  // horari del dia expandit. Es passa la data perquè el controller
  // pugui reintentar només aquell dia sense afectar la resta.
  final Future<void> Function(String date) onHourlyRetryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildBody(),
        ],
      ),
    );
  }

  // Aquest mètode pinta la capçalera de la card amb el títol principal i
  // un subtítol que indica l'horitzó de la previsió. Es manté separat per
  // si en el futur cal afegir-hi accions secundàries (canviar dies, etc.).
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Text(
            'Previsió meteorològica',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17212B),
            ),
          ),
        ),
        if (_subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            _subtitle!,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ],
    );
  }

  // Aquest getter compon el subtítol amb el nombre real de dies
  // retornats pel backend. Durant la càrrega inicial es retorna null
  // perquè la card no prometi un horitzó (per exemple "7 dies") que el
  // backend potser no acaba retornant.
  String? get _subtitle {
    final days = forecast?.days.length;
    if (days == null) {
      return null;
    }
    return days == 1 ? '1 dia' : '$days dies';
  }

  // Aquest mètode tria el cos de la card segons l'estat actual.
  // L'ordre de prioritat és: error sense dades > càrrega inicial > dades
  // disponibles. Si hi ha previsió cachejada, es prefereix mostrar-la
  // encara que s'estigui recarregant en segon pla, per evitar que la
  // pantalla "parpellegi" cada vegada que es fa pull-to-refresh.
  Widget _buildBody() {
    final currentForecast = forecast;

    if (errorMessage != null && (currentForecast == null || currentForecast.isEmpty)) {
      return _WeatherErrorState(
        message: errorMessage!,
        onRetryTap: onRetryTap,
      );
    }

    if (currentForecast == null) {
      return const _WeatherSkeleton();
    }

    if (currentForecast.isEmpty) {
      return const _WeatherEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 156,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: currentForecast.days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final day = currentForecast.days[index];
              final isExpanded = expandedDay == day.date;
              return _DayPill(
                day: day,
                isToday: index == 0,
                isExpanded: isExpanded,
                onTap: () => onDayTap(day.date),
              );
            },
          ),
        ),
        // L'AnimatedSize anima l'aparició i la desaparició del panell
        // horari per donar una sensació de continuïtat amb la fila de
        // píldores en lloc d'un salt brusc. Quan no hi ha cap dia
        // expandit, el SizedBox.shrink redueix l'altura a zero i
        // l'animació transiciona suaument.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: expandedDay == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: _HourlyPanel(
                    date: expandedDay!,
                    dayLabel: _fullDayLabelFor(expandedDay!),
                    hourly: expandedHourly,
                    isLoading: isExpandedHourlyLoading,
                    errorMessage: expandedHourlyError,
                    onRetryTap: () => onHourlyRetryTap(expandedDay!),
                  ),
                ),
        ),
      ],
    );
  }
}

// Aquest widget representa la píldora d'un dia dins del carrusel.
// Combina etiqueta diària, icona de la condició dominant i temperatures
// mínima i màxima. La píldora es ressalta quan és el dia actual o quan
// està expandida, perquè l'usuari identifiqui ràpidament a quin dia
// pertany el panell horari obert.
class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.day,
    required this.isToday,
    required this.isExpanded,
    required this.onTap,
  });

  final DailyForecast day;
  final bool isToday;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final type =
        day.dominantCondition?.normalized ?? WeatherConditionType.unknown;
    final accent = weatherAccentColorFor(type);
    // El ressaltat per expansió té prioritat sobre el d'avui: quan un dia
    // qualsevol està obert, és l'únic que mostra el fons reforçat. El
    // dia actual sense expandir manté un to més suau perquè es noti la
    // diferència entre "estic mirant aquest dia" i "aquest és avui".
    final background = isExpanded
        ? accent.withValues(alpha: 0.22)
        : isToday
            ? accent.withValues(alpha: 0.14)
            : const Color(0xFFF5F7FB);
    final borderColor = isExpanded
        ? accent
        : isToday
            ? accent.withValues(alpha: 0.4)
            : null;

    // Es valora la severitat del vent del bloc diürn (o nocturn com a
    // fallback) per pintar una etiqueta destacada quan supera el
    // llindar moderat. Quan el vent és tranquil, la línia inferior
    // queda buida però es reserva l'espai perquè totes les pílules
    // mantinguin la mateixa altura i el carrusel no quedi irregular.
    final windBlock = day.daytime ?? day.nighttime;
    final windSeverity = windSeverityFor(
      speedKmh: windBlock?.windSpeedKmh,
      gustKmh: windBlock?.windGustKmh,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 78,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: borderColor != null
                ? Border.all(
                    color: borderColor,
                    width: isExpanded ? 1.6 : 1.2,
                  )
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    _dayLabelFor(day.date, isToday),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dayNumberFor(day.date),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17212B),
                    ),
                  ),
                ],
              ),
              weatherIconWidget(
                type,
                size: 28,
                color: accent,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTemp(day.maxTempC),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17212B),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTemp(day.minTempC),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              _DayWindLine(severity: windSeverity),
            ],
          ),
        ),
      ),
    );
  }
}

// Aquest widget pinta la línia inferior amb l'indicador de vent del
// dia. Quan el vent és calm, retorna un espai reservat de la mateixa
// altura: així totes les pílules del carrusel mantenen la mateixa
// dimensió, encara que només algunes mostrin badge.
class _DayWindLine extends StatelessWidget {
  const _DayWindLine({required this.severity});

  final WindSeverity severity;

  @override
  Widget build(BuildContext context) {
    if (!severity.shouldHighlight) {
      return const SizedBox(height: 16);
    }
    final color = windSeverityColor(severity);
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      // Padding reduït (4 px horitzontal en lloc de 6) i icona-text amb
      // separació mínima per encabir "Molt fort" dins dels 62 px d'amplada
      // útil de la pílula diària. La separació prèvia provocava 5-6 px
      // d'overflow horitzontal amb "Vent fort".
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.air,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          // Flexible amb FittedBox actua de xarxa de seguretat per a
          // fonts del dispositiu lleugerament més amples del calculat.
          // En el cas normal, el text es pinta sense escalat.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                severity.shortLabel,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Aquest widget mostra el panell horari del dia expandit. Es comporta
// igual que la card sencera respecte als estats: si hi ha hores
// cachejades, es pinten encara que es recarreguin en segon pla; només
// es mostra error o esquelet quan no hi ha res en memòria.
class _HourlyPanel extends StatelessWidget {
  const _HourlyPanel({
    required this.date,
    required this.dayLabel,
    required this.hourly,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetryTap,
  });

  final String date;
  // Etiqueta natural ("Avui", "Demà", "Dilluns 13") del dia desplegat.
  // Es passa des del pare ja calculada perquè el panell no hagi
  // d'accedir a la data actual ni a la llista de noms en català.
  final String dayLabel;
  final PeakHourlyWeather? hourly;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Color(0xFF6B7280),
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'Previsió per hores',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              if (dayLabel.isNotEmpty) ...[
                const SizedBox(width: 6),
                Text(
                  '· $dayLabel',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _buildBody(),
        ],
      ),
    );
  }

  // L'ordre de prioritat dels estats és anàleg al de la card principal:
  // error sense dades > càrrega sense dades > buit > contingut. Si
  // arriba un error mentre ja hi havia hores cachejades, es prefereix
  // continuar mostrant les hores en lloc d'una pantalla d'error: una
  // recàrrega que falla intermitentment no ha de buidar dades vàlides
  // que l'usuari ja estava veient.
  Widget _buildBody() {
    final currentHourly = hourly;

    if (errorMessage != null && (currentHourly == null || currentHourly.isEmpty)) {
      return _HourlyErrorState(
        message: errorMessage!,
        onRetryTap: onRetryTap,
      );
    }

    if (currentHourly == null) {
      return const _HourlySkeleton();
    }

    if (currentHourly.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Text(
          'No hi ha dades horàries disponibles per a aquest dia.',
          style: TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
          ),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: currentHourly.hours.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _HourlyPill(hour: currentHourly.hours[index]);
        },
      ),
    );
  }
}

// Aquest widget representa una única hora dins del panell horari.
// Es manté compacte perquè 24 hores càpiguen còmodament en una fila
// scrollable sense forçar el dispositiu a renderitzar elements grans
// fora de pantalla.
class _HourlyPill extends StatelessWidget {
  const _HourlyPill({required this.hour});

  final HourlyForecast hour;

  @override
  Widget build(BuildContext context) {
    final type = hour.condition?.normalized ?? WeatherConditionType.unknown;
    final accent = weatherAccentColorFor(type);
    final precipPct = hour.precipProbabilityPct;
    final windSeverity = windSeverityFor(
      speedKmh: hour.windSpeedKmh,
      gustKmh: hour.windGustKmh,
    );

    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatHour(hour),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
          weatherIconWidget(
            type,
            size: 22,
            color: accent,
            // Quan Google ens diu que aquesta hora és nocturna, sunny i
            // partlyCloudy canvien automàticament a lluna en lloc de
            // sol. Si el camp arriba null, es manté el comportament de
            // dia per defecte.
            isDaytime: hour.isDaytime ?? true,
          ),
          Text(
            _formatTemp(hour.temperatureC),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17212B),
            ),
          ),
          // La línia inferior compon precipitació i vent en un únic
          // espai. Si una hora té tots dos, pinta el percentatge de
          // pluja al costat d'una petita icona de vent per no obligar
          // a triar només una dada. Si només hi ha pluja o només
          // vent, pinta el que correspongui. En hores calmes i seques
          // es manté un espai buit perquè totes les píldores
          // conservin la mateixa altura i el carrusel no quedi
          // dentat.
          _HourlyFooter(
            precipPct: precipPct,
            windSeverity: windSeverity,
            windSpeedKmh: hour.windSpeedKmh,
          ),
        ],
      ),
    );
  }
}

// Aquest widget pinta la línia inferior d'una píldora horària amb
// l'estat combinat de precipitació i vent. Cobreix els quatre casos
// (només pluja, només vent, ambdós, cap) amb un únic component per
// evitar que els crides hagin de duplicar la lògica de prioritat.
class _HourlyFooter extends StatelessWidget {
  const _HourlyFooter({
    required this.precipPct,
    required this.windSeverity,
    required this.windSpeedKmh,
  });

  final int precipPct;
  final WindSeverity windSeverity;
  final double? windSpeedKmh;

  @override
  Widget build(BuildContext context) {
    final hasPrecip = precipPct > 0;
    final hasWind = windSeverity.shouldHighlight;

    if (!hasPrecip && !hasWind) {
      return const SizedBox(height: 14);
    }

    final windColor = windSeverityColor(windSeverity);
    final children = <Widget>[];

    if (hasPrecip) {
      children.add(
        Text(
          '$precipPct%',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: weatherAccentColorFor(WeatherConditionType.rainy),
          ),
        ),
      );
    }

    if (hasPrecip && hasWind) {
      children.add(const SizedBox(width: 4));
    }

    if (hasWind) {
      children.add(
        Icon(
          Symbols.air,
          size: 12,
          color: windColor,
        ),
      );
      // Quan no plou, hi ha espai per pintar la velocitat real del
      // vent al costat de la icona. Si plou, mantenim només la
      // icona per no atapeir la línia.
      if (!hasPrecip && windSpeedKmh != null) {
        children.add(const SizedBox(width: 2));
        children.add(
          Text(
            '${windSpeedKmh!.round()}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: windColor,
            ),
          ),
        );
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}

// Aquest widget representa l'estat de càrrega del panell horari.
// Mostra 12 caixes (mitja jornada) per donar una sensació coherent de
// llargada respecte al carrusel real sense haver de pintar les 24.
class _HourlySkeleton extends StatelessWidget {
  const _HourlySkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 12,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => Container(
          width: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// Aquest widget mostra l'estat d'error del panell horari amb un botó
// per reintentar només la càrrega del dia expandit.
class _HourlyErrorState extends StatelessWidget {
  const _HourlyErrorState({
    required this.message,
    required this.onRetryTap,
  });

  final String message;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF9CA3AF),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          TextButton(
            onPressed: onRetryTap,
            child: const Text('Reintenta'),
          ),
        ],
      ),
    );
  }
}

// Aquest widget representa l'estat de càrrega inicial mentre encara no
// hi ha cap previsió descarregada. Mostra set caixes en gris perquè la
// card mantingui la mida i no salti quan arribin les dades.
class _WeatherSkeleton extends StatelessWidget {
  const _WeatherSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: 78,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF1F6),
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

// Aquest widget mostra el missatge quan Google retorna previsió buida.
// És diferent de l'estat d'error perquè aquí la petició ha funcionat,
// simplement no hi ha dades a l'horitzó sol·licitat.
class _WeatherEmptyState extends StatelessWidget {
  const _WeatherEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Encara no hi ha previsió disponible per a aquest cim.',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }
}

// Aquest widget mostra el missatge d'error i el botó de reintentar quan
// la càrrega ha fallat. Es manté minimalista per no quedar massa
// agressiu visualment quan apareix en una pantalla amb la resta de
// dades correctes.
class _WeatherErrorState extends StatelessWidget {
  const _WeatherErrorState({
    required this.message,
    required this.onRetryTap,
  });

  final String message;
  final Future<void> Function() onRetryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF9CA3AF),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetryTap,
            child: const Text('Reintenta'),
          ),
        ],
      ),
    );
  }
}

// Aquest mètode tradueix la data ISO en una etiqueta curta del dia en
// català. El primer dia es marca com "Avui" perquè l'usuari el reconegui
// immediatament sense haver de comparar amb la data actual.
String _dayLabelFor(String date, bool isToday) {
  if (isToday) {
    return 'AVUI';
  }
  final parsed = DateTime.tryParse(date);
  if (parsed == null) {
    return '';
  }
  // weekday: Dilluns=1, Dimarts=2, Dimecres=3, Dijous=4, Divendres=5,
  // Dissabte=6, Diumenge=7. Es manté la convenció Dart estàndard.
  const labels = ['DL', 'DM', 'DX', 'DJ', 'DV', 'DS', 'DG'];
  final index = parsed.weekday - 1;
  if (index < 0 || index >= labels.length) {
    return '';
  }
  return labels[index];
}

// Aquest mètode composa l'etiqueta natural d'un dia per a la cabecera
// del panell horari: "Avui" si és la data actual, "Demà" si és el dia
// següent, o el nom del dia amb el número de mes ("Dilluns 13") per a
// dates més enllà. Si la data no es pot parsejar, retorna la cadena
// original perquè la UI no quedi en blanc sense pista.
String _fullDayLabelFor(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) {
    return date;
  }
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final normalized = DateTime(parsed.year, parsed.month, parsed.day);
  final diff = normalized.difference(today).inDays;
  if (diff == 0) return 'Avui';
  if (diff == 1) return 'Demà';
  const labels = [
    'Dilluns',
    'Dimarts',
    'Dimecres',
    'Dijous',
    'Divendres',
    'Dissabte',
    'Diumenge',
  ];
  final index = parsed.weekday - 1;
  if (index < 0 || index >= labels.length) {
    return date;
  }
  return '${labels[index]} ${parsed.day}';
}

// Aquest mètode extreu el dia del mes d'una data ISO YYYY-MM-DD.
// Es retorna com a String per evitar mostrar un zero quan la data no
// es pot parsejar (per exemple, si arriba un format inesperat).
String _dayNumberFor(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) {
    return '';
  }
  return parsed.day.toString();
}

// Aquest mètode formata una temperatura per a la píldora del dia. Quan
// no hi ha dada disponible es retorna un guió per mantenir la mida del
// component constant i evitar saltets visuals entre dies.
String _formatTemp(double? celsius) {
  if (celsius == null) {
    return '—';
  }
  return '${celsius.round()}°';
}

// Aquest mètode formata l'etiqueta horària a partir del camp local.
// Quan no es pot determinar l'hora, retorna una cadena buida en lloc
// de "00" per evitar mostrar mitjanits enganyoses.
String _formatHour(HourlyForecast hour) {
  final h = hour.hourOfDay;
  if (h == null) {
    return '';
  }
  return '${h.toString().padLeft(2, '0')}h';
}
