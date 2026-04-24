export 'api/api_exception.dart';
export 'api/auth_api_client.dart';
export 'api/peaks_api_client.dart';
export 'api/profile_api_client.dart';
export 'api/regions_api_client.dart';

import 'package:cims/core/client/api/auth_api_client.dart';
import 'package:cims/core/client/api/peaks_api_client.dart';
import 'package:cims/core/client/api/profile_api_client.dart';
import 'package:cims/core/client/api/regions_api_client.dart';

// Aquest contracte agrupa tots els mòduls funcionals de l’API en un sol punt d’accés.
// No implementa cap lògica per si mateix, sinó que defineix que qualsevol classe que
// el faci servir ha d’oferir totes les operacions d’autenticació, perfil, cims i regions.
// Això permet que la resta de l’aplicació treballi amb una única referència comuna
// sense haver de dependre de cada mòdul per separat.
abstract class ApiClient
    implements
        AuthApiClient,
        ProfileApiClient,
        PeaksApiClient,
        RegionsApiClient {}
