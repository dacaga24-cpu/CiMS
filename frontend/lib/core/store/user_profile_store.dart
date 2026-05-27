import 'package:cims/core/entity/user.dart';
import 'package:flutter/foundation.dart';

// Aquest store manté el perfil de l’usuari autenticat durant la sessió.
// Permet compartir dades com el nom, el correu i la foto de perfil entre diferents pantalles.
class UserProfileStore extends ChangeNotifier {
  User? _user;

  // Retorna el perfil carregat de l’usuari actual.
  // Pot ser null si encara no s’ha carregat o si la sessió s’ha tancat.
  User? get user => _user;

  // Retorna la URL de la foto de perfil de l’usuari.
  // Facilita que els widgets puguin mostrar-la sense accedir a tot el perfil.
  String? get profilePhotoUrl => _user?.profilePhotoUrl;

  // Aquest mètode actualitza el perfil compartit.
  // És útil quan es carrega el perfil o quan l’usuari modifica dades del compte.
  void setUser(User user) {
    _user = user;
    notifyListeners();
  }

  // Aquest mètode buida el perfil compartit.
  // S’utilitza quan l’usuari tanca sessió o quan la sessió deixa de ser vàlida.
  void clear() {
    _user = null;
    notifyListeners();
  }
}