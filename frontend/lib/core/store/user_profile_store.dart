import 'package:cims/core/entity/user.dart';
import 'package:flutter/foundation.dart';

// Aquest store manté el perfil de l’usuari autenticat durant la sessió.
// Permet que diferents pantalles comparteixin la mateixa informació,
// com el nom, el correu i la foto de perfil.
class UserProfileStore extends ChangeNotifier {
  User? _user;

  User? get user => _user;

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