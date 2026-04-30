import 'package:flutter/material.dart';

// Aquest widget mostra un error quan no es poden carregar les estadístiques.
// També ofereix una acció per tornar a intentar la consulta.
class StatsErrorState extends StatelessWidget {
  const StatsErrorState({
    super.key,
    required this.message,
    required this.onRetryTap,
  });

  // Aquestes dades defineixen el missatge visible i l’acció de recuperació.
  // Permeten reutilitzar el mateix estat d’error amb diferents causes.
  final String message;
  final Future<void> Function() onRetryTap;

  // Aquest mètode construeix l’estat visual d’error amb una acció de reintent.
  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 96, 32, 24),
      children: [
        const Icon(
          Icons.query_stats_rounded,
          size: 48,
          color: Color(0xFF9AA3B2),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 18),
        Center(
          child: FilledButton(
            onPressed: onRetryTap,
            child: const Text('Torna-ho a provar'),
          ),
        ),
      ],
    );
  }
}
