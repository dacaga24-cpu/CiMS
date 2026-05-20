import 'package:flutter/material.dart';

// Aquest widget mostra una etiqueta visual per indicar que una ascensió o cim
// té una verificació acceptada. Es reutilitza en diferents pantalles perquè
// l’estat verificat tingui sempre el mateix estil dins l’aplicació.
class AscentVerifiedBadge extends StatelessWidget {
  const AscentVerifiedBadge({
    super.key,
    this.label = 'Verificat',
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: compact ? 13 : 15,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
