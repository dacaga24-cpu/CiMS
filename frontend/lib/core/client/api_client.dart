export 'api/api_exception.dart';
export 'api/auth_api_client.dart';
export 'api/ascents_api_client.dart';
export 'api/peak_status_api_client.dart';
export 'api/peaks_api_client.dart';
export 'api/profile_api_client.dart';
export 'api/regions_api_client.dart';
export 'api/stats_api_client.dart';
export 'api/monthly_challenge_api_client.dart';

import 'package:cims/core/client/api/ascents_api_client.dart';
import 'package:cims/core/client/api/auth_api_client.dart';
import 'package:cims/core/client/api/peak_status_api_client.dart';
import 'package:cims/core/client/api/peaks_api_client.dart';
import 'package:cims/core/client/api/profile_api_client.dart';
import 'package:cims/core/client/api/regions_api_client.dart';
import 'package:cims/core/client/api/stats_api_client.dart';
import 'package:cims/core/client/api/monthly_challenge_api_client.dart';

// Aquest contracte agrupa tots els mòduls funcionals de l’API.
// Així la resta del projecte pot continuar depenent d’un únic punt d’entrada,
// encara que internament les operacions estiguin separades per funcionalitat.
abstract class ApiClient
    implements
        AuthApiClient,
        AscentsApiClient,
        PeakStatusApiClient,
        ProfileApiClient,
        PeaksApiClient,
        RegionsApiClient,
        StatsApiClient,
        MonthlyChallengeApiClient {}
