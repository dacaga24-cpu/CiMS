import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquest widget representa provisionalment el mapa de cims.
// Més endavant es podrà substituir pel component real de Google Maps
// mantenint la mateixa entrada de dades i callbacks principals.
class PeaksMapPlaceholder extends StatelessWidget {
  const PeaksMapPlaceholder({
    super.key,
    required this.peaks,
    required this.selectedPeak,
    required this.onPeakTap,
  });

  // Aquest bloc rep els cims que s’han de representar i el cim seleccionat.
  // També rep l’acció que s’executa quan l’usuari toca un marcador del mapa.
  final List<Peak> peaks;
  final Peak? selectedPeak;
  final ValueChanged<Peak> onPeakTap;

  // Construeix el mapa provisional amb fons visual, marcadors i resum inferior.
  // Encara no utilitza Google Maps, però permet validar el flux funcional de selecció de cims.
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFE8EEF5),
            Color(0xFFD9E2EC),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const _MapBackground(),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: peaks.map((peak) {
                  return _MapPeakMarker(
                    peak: peak,
                    isSelected: selectedPeak?.id == peak.id,
                    left: _calculateLeft(
                      peak: peak,
                      width: constraints.maxWidth,
                    ),
                    top: _calculateTop(
                      peak: peak,
                      height: constraints.maxHeight,
                    ),
                    onTap: () => onPeakTap(peak),
                  );
                }).toList(),
              );
            },
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: _MapSummaryBadge(
              totalPeaks: peaks.length,
            ),
          ),
        ],
      ),
    );
  }

  // Calcula la posició horitzontal del marcador a partir de la longitud del cim.
  // Aquesta conversió permet situar visualment cada cim dins del mapa provisional.
  double _calculateLeft({
    required Peak peak,
    required double width,
  }) {
    final longitude = peak.longitude ?? 0;
    const minLongitude = 0.0;
    const maxLongitude = 3.5;

    final normalized = ((longitude - minLongitude) / (maxLongitude - minLongitude))
        .clamp(0.05, 0.95);

    return normalized * (width - 34);
  }

  // Calcula la posició vertical del marcador a partir de la latitud del cim.
  // Això permet aproximar la distribució dels cims dins de l’espai visual del mapa.
  double _calculateTop({
    required Peak peak,
    required double height,
  }) {
    final latitude = peak.latitude ?? 0;
    const minLatitude = 40.5;
    const maxLatitude = 42.9;

    final normalized = 1 -
        ((latitude - minLatitude) / (maxLatitude - minLatitude))
            .clamp(0.08, 0.88);

    return normalized * (height - 48);
  }
}

// Aquest fons dona una sensació visual de mapa sense dependre encara
// de cap SDK extern ni de cap clau d’API.
class _MapBackground extends StatelessWidget {
  const _MapBackground();

  // Dibuixa el fons decoratiu que simula línies i zones d’un mapa.
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapBackgroundPainter(),
      child: const SizedBox.expand(),
    );
  }
}

// Aquest marcador representa un cim dins del mapa provisional.
// Quan l’usuari el toca, la pantalla mostra la targeta resum del cim seleccionat.
class _MapPeakMarker extends StatelessWidget {
  const _MapPeakMarker({
    required this.peak,
    required this.isSelected,
    required this.left,
    required this.top,
    required this.onTap,
  });

  // Aquest bloc defineix la informació i el comportament del marcador.
  // La posició situa el cim al mapa i l’estat seleccionat modifica la seva aparença.
  final Peak peak;
  final bool isSelected;
  final double left;
  final double top;
  final VoidCallback onTap;

  // Construeix el marcador interactiu del cim.
  // La mida i el color canvien quan el cim està seleccionat per fer-lo més visible.
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isSelected ? 34 : 24,
          height: isSelected ? 34 : 24,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0B57D0) : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF0B57D0),
              width: isSelected ? 3 : 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.landscape_rounded,
            size: isSelected ? 17 : 13,
            color: isSelected ? Colors.white : const Color(0xFF0B57D0),
          ),
        ),
      ),
    );
  }
}

// Aquest element resumeix quants cims s’estan mostrant al mapa.
class _MapSummaryBadge extends StatelessWidget {
  const _MapSummaryBadge({
    required this.totalPeaks,
  });

  // Nombre total de cims visibles amb la cerca i els filtres actuals.
  final int totalPeaks;

  // Mostra una etiqueta informativa sobre el volum de cims representats.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '$totalPeaks cims visibles al mapa',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF17212B),
        ),
      ),
    );
  }
}

// Aquest painter dibuixa el fons decoratiu del mapa provisional.
// Ajuda a donar context visual mentre encara no s’ha integrat el mapa real.
class _MapBackgroundPainter extends CustomPainter {
  // Dibuixa línies i una zona suau per simular una superfície cartogràfica.
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1.4;

    for (double x = 0; x < size.width; x += 38) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + 70, size.height),
        linePaint,
      );
    }

    for (double y = 20; y < size.height; y += 44) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y - 28),
        linePaint,
      );
    }

    final areaPaint = Paint()
      ..color = const Color(0x3326A269)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.28)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.08,
        size.width * 0.78,
        size.height * 0.22,
      )
      ..quadraticBezierTo(
        size.width * 0.92,
        size.height * 0.52,
        size.width * 0.62,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.86,
        size.width * 0.18,
        size.height * 0.28,
      );

    canvas.drawPath(path, areaPaint);
  }

  // Indica que el fons no necessita redibuixar-se perquè és estàtic.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}