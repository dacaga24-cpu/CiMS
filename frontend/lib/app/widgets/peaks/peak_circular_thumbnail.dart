import 'package:flutter/material.dart';

// Aquest widget mostra una imatge circular representativa d’un cim.
// Si el backend envia una imatge pública del catàleg, es mostra des del bucket.
// Si no hi ha imatge o falla la càrrega, es manté la imatge local de reserva.
class PeakCircularThumbnail extends StatelessWidget {
  const PeakCircularThumbnail({
    super.key,
    this.size = 58,
    this.imageUrl,
  });

  // Aquesta mida permet reutilitzar la miniatura en diferents pantalles,
  // com el catàleg o la targeta ràpida del mapa.
  final double size;

  // Aquesta URL permet mostrar la foto real del cim quan està disponible.
  // Normalment prové del camp imageUrl retornat pel backend.
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: url == null || url.isEmpty
            ? Image.asset(
                'assets/images/montana_0001.png',
                fit: BoxFit.cover,
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/montana_0001.png',
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}
