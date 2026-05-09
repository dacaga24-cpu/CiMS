import 'package:flutter/material.dart';

// Aquest widget mostra una imatge circular representativa d’un cim.
// De moment utilitza una imatge local comuna per a tots els cims,
// però deixa preparada la interfície per substituir-la més endavant
// per imatges específiques de cada muntanya.
class PeakCircularThumbnail extends StatelessWidget {
  const PeakCircularThumbnail({
    super.key,
    this.size = 58,
  });

  // Aquesta mida permet reutilitzar la miniatura en diferents pantalles,
  // com el catàleg o la targeta ràpida del mapa.
  final double size;

  @override
  Widget build(BuildContext context) {
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
        child: Image.asset(
          'assets/images/montana_0001.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}