import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:geolocator_web/geolocator_web.dart';

// Workaround: força el registre del plugin web del geolocator.
//
// El `web_plugin_registrant.dart` autogenerat ja inclou aquesta crida,
// però en aquest toolchain (Flutter 3.38.x) dart2js considera la cadena
// `GeolocatorPlugin.registerWith` → `GeolocatorPlatform.instance = …` com
// a side effect descartable i la treu del bundle final. Resultat: a la web
// `Geolocator.getCurrentPosition` peta amb `MissingPluginException` perquè
// `GeolocatorPlatform.instance` queda en la implementació per defecte (que
// delega a un MethodChannel sense handler nadiu al navegador).
//
// La crida sola no n'hi ha prou: cal un side effect observable (un `print`
// que llegeixi `runtimeType.toString()`) perquè dart2js no pugui demostrar
// que tota la cadena és morta i la conservi al bundle final. Patró
// documentat com a workaround a github.com/dart-lang/sdk/issues/52968.
void ensureWebPluginsRegistered() {
  GeolocatorPlugin.registerWith(webPluginRegistrar);
  // ignore: avoid_print
  print('[CiMS] geolocator web: ${GeolocatorPlatform.instance.runtimeType}');
}
