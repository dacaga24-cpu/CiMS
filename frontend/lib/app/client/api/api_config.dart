// Aquesta classe centralitza la configuració de la connexió amb el backend.
// La seva funció és decidir quina URL base s'ha d'utilitzar segons l'entorn
// sense repartir aquesta lògica per diferents fitxers del projecte.
class ApiConfig {
  // Aquesta constant permet definir l'URL del backend des de fora del codi
  // quan es compila o s'executa l'aplicació (via --dart-define=API_BASE_URL=...).
  // És el mecanisme previst per apuntar a un backend local durant el
  // desenvolupament o a qualsevol entorn alternatiu (staging, preview...).
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  // Aquesta constant defineix la URL del backend de producció desplegat a
  // Google Cloud Run. S'utilitza com a valor per defecte perquè el build
  // publicat a Firebase Hosting funcioni sense dependre d'un flag que un
  // humà hagi de recordar en cada desplegament. Si en el futur s'afegís un
  // domini propi, aquest és l'únic lloc on caldria actualitzar-lo.
  static const String _productionBaseUrl =
      'https://cims-backend-639822259289.europe-southwest1.run.app';

  // Aquesta propietat exposa l'adreça base final que farà servir l'aplicació.
  // Si s'ha passat una URL explícita via variable d'entorn, té prioritat;
  // en cas contrari, s'apunta directament al backend de producció tant si
  // l'aplicació corre en web, com en Android o en iOS. D'aquesta manera
  // un build sense configuració queda sempre en un estat operatiu i no es
  // filtra cap petició a la xarxa local del client.
  static String get baseUrl {
    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
    }
    return _productionBaseUrl;
  }
}
