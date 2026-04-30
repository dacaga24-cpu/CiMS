import 'package:flutter/material.dart';

// Aquest widget informa que el cim encara no té ascensions registrades.
// Permet mantenir la pantalla útil encara que l’historial estigui buit.
class AscentHistoryEmptyState extends StatelessWidget {
  const AscentHistoryEmptyState({super.key});

  // Aquest mètode construeix un missatge senzill per indicar que no hi ha dades.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 26,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.hiking_rounded,
            size: 34,
            color: Color(0xFF0F5ADB),
          ),
          SizedBox(height: 12),
          Text(
            'Encara no hi ha ascensions registrades per aquest cim.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}