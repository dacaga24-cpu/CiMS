import 'package:flutter/material.dart';

// Aquest widget mostra els missatges d’error puntuals relacionats amb el detall.
// Separa els avisos de l’estat del cim i de les ascensions per no carregar la screen.
class PeakDetailStatusMessages extends StatelessWidget {
  const PeakDetailStatusMessages({
    super.key,
    required this.statusErrorMessage,
    required this.ascentsErrorMessage,
  });

  // Missatges opcionals que poden aparèixer després d’actualitzar estats
  // o recuperar dades d’ascensions.
  final String? statusErrorMessage;
  final String? ascentsErrorMessage;

  @override
  Widget build(BuildContext context) {
    if (statusErrorMessage == null && ascentsErrorMessage == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (statusErrorMessage != null) ...[
          const SizedBox(height: 12),
          _PeakDetailStatusMessage(statusErrorMessage!),
        ],
        if (ascentsErrorMessage != null) ...[
          const SizedBox(height: 12),
          _PeakDetailStatusMessage(ascentsErrorMessage!),
        ],
      ],
    );
  }
}

// Aquest text intern manté un estil uniforme per als avisos del detall.
class _PeakDetailStatusMessage extends StatelessWidget {
  const _PeakDetailStatusMessage(this.message);

  // Contingut del missatge que es mostrarà a l’usuari.
  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(
        color: Color(0xFFE84A4A),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
