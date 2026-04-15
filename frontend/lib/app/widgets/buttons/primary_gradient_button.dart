import 'package:flutter/material.dart';

// Aquest botó reutilitzable representa l’acció principal dels formularis.
// Manté el mateix estil visual i el mateix comportament de càrrega a diferents pantalles.
class PrimaryGradientButton extends StatelessWidget {
  const PrimaryGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  // Aquest bloc recull la informació bàsica del botó:
  // el text, l’acció, l’estat de càrrega i una icona opcional.
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  // Aquest mètode construeix el botó principal amb degradat i indicador de càrrega.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0E63F4),
              Color(0xFF0047C7),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x220047C7),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
