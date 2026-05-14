import 'dart:typed_data';

import 'package:cims/core/entity/nearby_peak_candidate.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

// Aquesta targeta mostra el resultat del flux de verificació ràpida.
// Inclou la ubicació capturada, els cims propers, la foto feta des de l’app
// i les accions per crear l’ascensió verificada.
class AscentVerificationCaptureCard extends StatelessWidget {
  const AscentVerificationCaptureCard({
    super.key,
    required this.isLoading,
    required this.message,
    required this.errorMessage,
    required this.position,
    required this.capturedAt,
    required this.photoBytes,
    required this.onCreateVerifiedAscentTap,
    required this.onCompleteLaterTap,
    required this.onRetryTap,
    required this.nearbyPeakCandidates,
    required this.selectedNearbyPeakCandidate,
    required this.isLoadingNearbyPeaks,
    required this.onNearbyPeakTap,
    required this.onCapturePhotoTap,
  });

  final bool isLoading;
  final String? message;
  final String? errorMessage;
  final Position? position;
  final DateTime? capturedAt;
  final Uint8List? photoBytes;
  final VoidCallback onCreateVerifiedAscentTap;
  final VoidCallback onCompleteLaterTap;
  final VoidCallback onRetryTap;
  final List<NearbyPeakCandidate> nearbyPeakCandidates;
  final NearbyPeakCandidate? selectedNearbyPeakCandidate;
  final bool isLoadingNearbyPeaks;
  final ValueChanged<NearbyPeakCandidate> onNearbyPeakTap;
  final VoidCallback onCapturePhotoTap;

  @override
  Widget build(BuildContext context) {
    final hasLocation = position != null;
    final hasEvidence = position != null && photoBytes != null;

    return SingleChildScrollView(
      child: Container(
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
              hasEvidence
                  ? 'Evidència capturada'
                  : hasLocation
                      ? 'Selecciona el cim'
                      : 'Preparant verificació',
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
            else if (errorMessage != null) ...[
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE84A4A),
                ),
              ),
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: onRetryTap,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tornar-ho a intentar'),
              ),
            ] else ...[
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
              if (capturedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Capturat: ${capturedAt!.day.toString().padLeft(2, '0')}/${capturedAt!.month.toString().padLeft(2, '0')}/${capturedAt!.year} · ${capturedAt!.hour.toString().padLeft(2, '0')}:${capturedAt!.minute.toString().padLeft(2, '0')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
              if (hasLocation) ...[
                const SizedBox(height: 22),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cim a verificar',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF344054),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (isLoadingNearbyPeaks)
                  const CircularProgressIndicator()
                else
                  ...nearbyPeakCandidates.map((candidate) {
                    final isSelected =
                        selectedNearbyPeakCandidate?.peak.id ==
                            candidate.peak.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onNearbyPeakTap(candidate),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEAF1FF)
                                : const Color(0xFFF8F9FB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0B57D0)
                                  : const Color(0xFFE4E7EC),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.radio_button_off_rounded,
                                color: isSelected
                                    ? const Color(0xFF0B57D0)
                                    : const Color(0xFF98A2B3),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  candidate.peak.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF344054),
                                  ),
                                ),
                              ),
                              Text(
                                '${candidate.distanceMeters.toStringAsFixed(0)} m',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF667085),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                if (!hasEvidence) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: selectedNearbyPeakCandidate == null
                          ? null
                          : onCapturePhotoTap,
                      icon: const Icon(Icons.photo_camera_rounded),
                      label: const Text('Fer foto de verificació'),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: onCreateVerifiedAscentTap,
                      icon: const Icon(Icons.verified_rounded),
                      label: const Text('Crear ascensió verificada'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: onCompleteLaterTap,
                      icon: const Icon(Icons.schedule_rounded),
                      label: const Text('Completar més tard'),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onRetryTap,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Repetir captura'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}