import 'package:flutter/material.dart';

// Aquest widget representa la zona reservada per a la futura pujada de foto.
// En aquesta iteració només mostra el disseny i deixa visible que la integració
// encara no està connectada.
class AscentRegisterPhotoCard extends StatelessWidget {
  const AscentRegisterPhotoCard({super.key});

  // Aquesta targeta reserva visualment l’espai de la imatge
  // perquè el formulari ja reflecteixi aquesta funcionalitat futura.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 170),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(
            Icons.add_a_photo_outlined,
            size: 32,
            color: Color(0xFF0B57D0),
          ),
          SizedBox(height: 12),

          // Aquest text indica de forma simple quina acció
          // s’hi podrà fer quan la funcionalitat estigui disponible.
          Text(
            'Selecciona una imatge',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
    );
  }
}