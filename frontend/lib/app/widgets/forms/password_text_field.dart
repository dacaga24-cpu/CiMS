import 'package:flutter/material.dart';

// Aquest widget mostra un camp de contrasenya amb opció de mostrar o amagar el text.
// S’utilitza en formularis que necessiten el comportament estàndard de Material.
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

  // Aquestes propietats configuren el comportament i el contingut del camp.
  // Permeten reutilitzar-lo en diferents formularis de contrasenya.
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
  // Aquest estat indica si la contrasenya es mostra o es manté amagada.
  // Per defecte queda oculta per protegir la privacitat de l’usuari.
  bool _obscured = true;

  // Aquest mètode alterna la visibilitat de la contrasenya.
  // Permet revisar el text escrit abans d’enviar el formulari.
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