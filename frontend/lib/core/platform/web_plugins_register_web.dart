import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:geolocator_web/geolocator_web.dart';

// Aquest mètode garanteix que el plugin web de geolocalització quedi registrat.
// És necessari perquè la captura d’ubicació funcioni correctament en builds web.
void ensureWebPluginsRegistered() {
  GeolocatorPlugin.registerWith(webPluginRegistrar);

  // Aquest registre manté un efecte observable durant la compilació web.
  // Això evita que el registre del plugin sigui eliminat del bundle final.
  // ignore: avoid_print
  print('[CiMS] geolocator web: ${GeolocatorPlatform.instance.runtimeType}');
}