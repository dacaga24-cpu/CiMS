import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Aquest widget reutilitzable mostra el logotip principal de CiMS.
// Serveix per mantenir una identitat visual coherent allà on l’aplicació
// necessita presentar la marca de manera simple i centralitzada.
class CimsLogo extends StatelessWidget {
  const CimsLogo({
    super.key,
    this.width = 120,
    this.height = 120,
  });

  // Aquest bloc permet ajustar la mida del logotip segons el context visual
  // on s’hagi de mostrar.
  final double width;
  final double height;

  // Aquest mètode construeix el logotip vectorial principal de l’aplicació.
  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/cims_logo.svg',
      width: width,
      height: height,
    );
  }
}
