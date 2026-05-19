import 'package:cims/app/theme/app_theme.dart';
import 'package:flutter/material.dart';

// Aquest botó es fa servir per a accions destructives (eliminar el compte,
// l'ascensió o una foto). Comparteix la forma de píndola dels botons
// primaris perquè s'integri bé als formularis, però amb el color de perill
// del tema per avisar visualment l'usuari abans de prémer-lo.
class DestructivePillButton extends StatelessWidget {
  const DestructivePillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  // Aquesta etiqueta hauria de descriure clarament què passarà (per
  // exemple "Desactivar compte" o "Eliminar ascensió"); evita textos
  // ambigus tipus "Continuar".
  final String label;

  // L'acció es deshabilita automàticament quan l'operació està en marxa
  // per evitar dobles clics que generin peticions duplicades.
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
