import 'package:flutter/material.dart';

// Aquest widget encapsula un camp de contrasenya amb el toggle d'ull
// "mostrar/amagar". Pensat per als formularis dins de modals/diàlegs que
// fan servir l'estil estàndard de Material (labelText flotant, errorText).
//
// Per als formularis amb estil de píndola (login/register) ja existeix
// `AppInputField`, que cada pantalla configura amb el seu propi botó d'ull
// connectat al controlador.
class PasswordTextField extends StatefulWidget {
  const PasswordTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
  });

  // Aquestes propietats configuren el camp: el controlador, l'etiqueta
  // flotant, el missatge d'error opcional i si està habilitat. Mantenen la
  // mateixa interfície que `TextField` per facilitar substituir-lo allà on
  // calgui.
  final TextEditingController controller;
  final String labelText;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  // Per defecte la contrasenya queda amagada; l'usuari pot revelar-la
  // manualment per evitar errors d'escriptura.
  bool _obscured = true;

  void _toggleObscured() {
    setState(() {
      _obscured = !_obscured;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscured,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        labelText: widget.labelText,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: _obscured ? 'Mostrar contrasenya' : 'Amagar contrasenya',
          icon: Icon(
            _obscured
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
          onPressed: widget.enabled ? _toggleObscured : null,
        ),
      ),
    );
  }
}
