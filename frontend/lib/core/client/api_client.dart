export 'api/api_exception.dart';
export 'api/auth_api_client.dart';
export 'api/peaks_api_client.dart';
export 'api/profile_api_client.dart';
export 'api/regions_api_client.dart';

import 'package:cims/core/client/api/auth_api_client.dart';
import 'package:cims/core/client/api/peaks_api_client.dart';
import 'package:cims/core/client/api/profile_api_client.dart';
import 'package:cims/core/client/api/regions_api_client.dart';

// Aquest contracte agrupa tots els mòduls funcionals de l’API.
// Així la resta del projecte pot continuar depenent d’un únic punt d’entrada.
abstract class ApiClient
    implements
        AuthApiClient,
        ProfileApiClient,
        PeaksApiClient,
        RegionsApiClient {}
