import 'package:flutter/material.dart';

// Aquest text separa visualment el bloc d’opcions del compte.
class ProfileSettingsSectionTitle extends StatelessWidget {
  const ProfileSettingsSectionTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 4),
      child: Text(
        'CONFIGURACIÓ',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.2,
          color: Color(0xFF9C9CA3),
        ),
      ),
    );
  }
}
