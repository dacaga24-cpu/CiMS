import 'package:flutter/material.dart';

// Aquest widget mostra un error quan no es poden carregar les ascensions.
// També ofereix una acció de reintent per tornar a executar la consulta.
class AscentHistoryErrorState extends StatelessWidget {
  const AscentHistoryErrorState({
    super.key,
    required this.message,
    required this.onRetryTap,
  });

  // Aquest bloc defineix el missatge d’error i l’acció disponible per recuperar la pantalla.
  final String message;
  final Future<void> Function() onRetryTap;

  // Aquest mètode construeix una targeta d’error clara i centrada en l’acció de reintent.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 24,
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
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 34,
            color: Color(0xFFE5484D),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetryTap,
            child: const Text(
              'Torna-ho a provar',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F5ADB),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
