import 'package:cims/core/entity/peak.dart';
import 'package:flutter/material.dart';

// Aquest widget mostra la descripció del cim quan el backend l’ha informat.
// Manté separat aquest bloc visual perquè la pantalla de detall sigui més lleugera.
class PeakDetailDescriptionCard extends StatelessWidget {
  const PeakDetailDescriptionCard({
    super.key,
    required this.peak,
  });

  // Aquesta propietat rep el cim del qual es mostrarà la descripció.
  final Peak peak;

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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Descripció',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17212B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            peak.description!,
            style: const TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}