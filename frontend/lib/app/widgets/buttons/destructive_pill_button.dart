import 'package:cims/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

// Aquest botó s’utilitza per a accions destructives o irreversibles.
// Manté l’estil de botó arrodonit, però utilitza el color de perill del tema.
class DestructivePillButton extends StatelessWidget {
  const DestructivePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  // Aquesta etiqueta descriu l’acció que executarà el botó.
  // Ha de ser clara perquè l’usuari entengui la conseqüència abans de prémer.
  final String label;

  // Aquesta acció s’executa quan l’usuari prem el botó.
  // Es desactiva mentre carrega per evitar peticions duplicades.
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.dangerColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.dangerColor.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}