import 'package:cims/core/entity/peak.dart';
import 'package:cims/core/entity/region.dart';
import 'package:cims/core/entity/user.dart';

// Aquesta classe representa un error relacionat amb la comunicació amb l’API.
// Serveix per traslladar a l’aplicació un missatge clar sobre què ha fallat
// i, si es disposa d’aquesta informació, el codi d’estat retornat pel servidor.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  // Aquest bloc guarda la informació bàsica de l’error
  // perquè després es pugui mostrar o gestionar des de la interfície.
  final String message;
  final int? statusCode;

  // Aquest mètode retorna el missatge de l’error en format text.
  @override
  String toString() => message;
}

// Aquesta classe representa la resposta que retorna el servidor
// quan l’usuari inicia sessió correctament.
// Agrupa la informació necessària per continuar amb la sessió dins de l’aplicació.
class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.userId,
    this.message,
  });

  // Aquest bloc recull les dades principals de la resposta de login:
  // el token de sessió, l’identificador de l’usuari i un missatge opcional.
  final String token;
  final int userId;
  final String? message;

  // Aquest constructor transforma la resposta rebuda del backend
  // en un objecte que l’aplicació pugui utilitzar fàcilment.
  // També comprova que les dades més importants siguin vàlides abans de continuar.
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final userIdRaw = json['userId'];
    int? parsedUserId;

    // Aquest bloc intenta adaptar el valor de userId al format enter
    // encara que el backend l’enviï amb un tipus lleugerament diferent.
    if (userIdRaw is int) {
      parsedUserId = userIdRaw;
    } else if (userIdRaw is num) {
      parsedUserId = userIdRaw.toInt();
    } else if (userIdRaw is String) {
      parsedUserId = int.tryParse(userIdRaw);
    }

    // Aquesta validació evita continuar la sessió amb dades incompletes
    // o incorrectes retornades pel servidor.
    if (parsedUserId == null) {
      throw const ApiException('El userId retornat pel servidor no és vàlid');
    }

    final token = json['token']?.toString();

    // Aquest control assegura que la resposta inclogui un token útil,
    // ja que sense aquest valor no es pot mantenir la sessió autenticada.
    if (token == null || token.isEmpty) {
      throw const ApiException('El token retornat pel servidor no és vàlid');
    }

    return LoginResponse(
      token: token,
      userId: parsedUserId,
      message: json['message'] as String?,
    );
  }
}

// Aquesta classe abstracta defineix el contracte bàsic del client d’API.
// És rellevant perquè estableix quines operacions ha de poder fer qualsevol
// implementació encarregada de comunicar-se amb el backend.
abstract class ApiClient {
  // Aquest mètode registra un nou usuari al sistema amb les dades bàsiques del compte.
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  // Aquest mètode autentica l’usuari i retorna la informació necessària
  // per iniciar i mantenir la sessió dins de l’aplicació.
  Future<LoginResponse> login({
    required String email,
    required String password,
  });

  // Aquest mètode recupera el perfil de l’usuari autenticat
  // per mostrar les seves dades dins de l’aplicació.
  Future<User> getUserProfile();

  // Aquest mètode inicia el procés de recuperació de contrasenya
  // a partir del correu electrònic indicat per l’usuari.
  Future<String> requestPasswordReset({
    required String email,
  });

  // Aquest mètode permet establir una nova contrasenya
  // quan l’usuari ja disposa d’un token de recuperació vàlid.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  // Aquest mètode recupera el catàleg de cims i admet filtres opcionals
  // per adaptar el resultat a la cerca o als criteris triats per l’usuari.
  Future<List<Peak>> getPeaks({
    String? search,
    int? regionId,
    int? minAltitude,
    int? maxAltitude,
  });

  // Aquest mètode obté la llista de comarques disponibles
  // per poder mostrar filtres i dades geogràfiques del catàleg.
  Future<List<Region>> getRegions();

  // Aquest mètode recupera el detall d’un cim concret
  // reutilitzant la mateixa entitat Peak del catàleg.
  Future<Peak> getPeakById(int peakId);
}

// Aquest error indica que la sessió ja no és vàlida per accedir a un endpoint protegit.
// Permet diferenciar un 401 de sessió caducada d’altres errors d’API.
class ApiUnauthorizedException extends ApiException {
  const ApiUnauthorizedException([
    super.message = 'La sessió ha caducat',
  ]) : super(statusCode: 401);
}