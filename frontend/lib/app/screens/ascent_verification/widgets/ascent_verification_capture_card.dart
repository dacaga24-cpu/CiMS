import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// Aquesta targeta informa l’usuari del resultat de la verificació ràpida.
// Mostra la ubicació capturada i la foto feta des de l’app abans d’enviar-les al backend.
class AscentVerificationCaptureCard extends StatelessWidget {
  const AscentVerificationCaptureCard({
    super.key,
    required this.isLoading,
    required this.message,
    required this.errorMessage,
    required this.position,
    required this.capturedAt,
    required this.photoBytes,
  });

  final bool isLoading;
  final String? message;
  final String? errorMessage;
  final Position? position;
  final DateTime? capturedAt;
  final Uint8List? photoBytes;

  @override
  Widget build(BuildContext context) {
    final hasEvidence = position != null && photoBytes != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: hasEvidence
                  ? const Color(0xFFEAF8F0)
                  : const Color(0xFFEAF1FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasEvidence
                  ? Icons.verified_outlined
                  : Icons.photo_camera_rounded,
              color: hasEvidence
                  ? const Color(0xFF18B56A)
                  : const Color(0xFF0B57D0),
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasEvidence ? 'Evidència capturada' : 'Preparant verificació',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1D2939),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'La verificació utilitza una foto feta des de l\'app i la ubicació capturada pel dispositiu en aquell moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(height: 22),
          if (isLoading)
            const CircularProgressIndicator()
          else if (errorMessage != null)
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE84A4A),
              ),
            )
          else ...[
            if (photoBytes != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.memory(
                  photoBytes!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (message != null)
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF18B56A),
                ),
              ),
            if (position != null) ...[
              const SizedBox(height: 12),
              Text(
                'Lat: ${position!.latitude.toStringAsFixed(6)} · Lng: ${position!.longitude.toStringAsFixed(6)} · Precisió: ${position!.accuracy.toStringAsFixed(0)} m',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
