// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AppStartScreen]
class AppStartRoute extends PageRouteInfo<void> {
  const AppStartRoute({List<PageRouteInfo>? children})
      : super(AppStartRoute.name, initialChildren: children);

  static const String name = 'AppStartRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AppStartScreen();
    },
  );
}

/// generated route for
/// [AscentRegisterScreen]
class AscentRegisterRoute extends PageRouteInfo<AscentRegisterRouteArgs> {
  AscentRegisterRoute({
    Key? key,
    required Peak peak,
    List<PageRouteInfo>? children,
  }) : super(
          AscentRegisterRoute.name,
          args: AscentRegisterRouteArgs(key: key, peak: peak),
          initialChildren: children,
        );

  static const String name = 'AscentRegisterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<AscentRegisterRouteArgs>();
      return AscentRegisterScreen(key: args.key, peak: args.peak);
    },
  );
}

class AscentRegisterRouteArgs {
  const AscentRegisterRouteArgs({this.key, required this.peak});

  final Key? key;

  final Peak peak;

  @override
  String toString() {
    return 'AscentRegisterRouteArgs{key: $key, peak: $peak}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AscentRegisterRouteArgs) return false;
    return key == other.key && peak == other.peak;
  }

  @override
  int get hashCode => key.hashCode ^ peak.hashCode;
}

/// generated route for
/// [DashboardScreen]
class DashboardRoute extends PageRouteInfo<void> {
  const DashboardRoute({List<PageRouteInfo>? children})
      : super(DashboardRoute.name, initialChildren: children);

  static const String name = 'DashboardRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const DashboardScreen();
    },
  );
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const LoginScreen();
    },
  );
}

/// generated route for
/// [MainNavigationScreen]
class MainNavigationRoute extends PageRouteInfo<void> {
  const MainNavigationRoute({List<PageRouteInfo>? children})
      : super(MainNavigationRoute.name, initialChildren: children);

  static const String name = 'MainNavigationRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainNavigationScreen();
    },
  );
}

/// generated route for
/// [PeakDetailScreen]
class PeakDetailRoute extends PageRouteInfo<PeakDetailRouteArgs> {
  PeakDetailRoute({
    Key? key,
    required int peakId,
    List<PageRouteInfo>? children,
  }) : super(
          PeakDetailRoute.name,
          args: PeakDetailRouteArgs(key: key, peakId: peakId),
          initialChildren: children,
        );

  static const String name = 'PeakDetailRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PeakDetailRouteArgs>();
      return PeakDetailScreen(key: args.key, peakId: args.peakId);
    },
  );
}

class PeakDetailRouteArgs {
  const PeakDetailRouteArgs({this.key, required this.peakId});

  final Key? key;

  final int peakId;

  @override
  String toString() {
    return 'PeakDetailRouteArgs{key: $key, peakId: $peakId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PeakDetailRouteArgs) return false;
    return key == other.key && peakId == other.peakId;
  }

  @override
  int get hashCode => key.hashCode ^ peakId.hashCode;
}

/// generated route for
/// [PeaksCatalogScreen]
class PeaksCatalogRoute extends PageRouteInfo<void> {
  const PeaksCatalogRoute({List<PageRouteInfo>? children})
      : super(PeaksCatalogRoute.name, initialChildren: children);

  static const String name = 'PeaksCatalogRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PeaksCatalogScreen();
    },
  );
}

/// generated route for
/// [PeaksMapScreen]
class PeaksMapRoute extends PageRouteInfo<PeaksMapRouteArgs> {
  PeaksMapRoute({Key? key, int? initialPeakId, List<PageRouteInfo>? children})
      : super(
          PeaksMapRoute.name,
          args: PeaksMapRouteArgs(key: key, initialPeakId: initialPeakId),
          initialChildren: children,
        );

  static const String name = 'PeaksMapRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PeaksMapRouteArgs>(
        orElse: () => const PeaksMapRouteArgs(),
      );
      return PeaksMapScreen(key: args.key, initialPeakId: args.initialPeakId);
    },
  );
}

class PeaksMapRouteArgs {
  const PeaksMapRouteArgs({this.key, this.initialPeakId});

  final Key? key;

  final int? initialPeakId;

  @override
  String toString() {
    return 'PeaksMapRouteArgs{key: $key, initialPeakId: $initialPeakId}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PeaksMapRouteArgs) return false;
    return key == other.key && initialPeakId == other.initialPeakId;
  }

  @override
  int get hashCode => key.hashCode ^ initialPeakId.hashCode;
}

/// generated route for
/// [ProfileSettingsScreen]
class ProfileSettingsRoute extends PageRouteInfo<ProfileSettingsRouteArgs> {
  ProfileSettingsRoute({
    Key? key,
    Future<void> Function()? onLogout,
    List<PageRouteInfo>? children,
  }) : super(
          ProfileSettingsRoute.name,
          args: ProfileSettingsRouteArgs(key: key, onLogout: onLogout),
          initialChildren: children,
        );

  static const String name = 'ProfileSettingsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ProfileSettingsRouteArgs>(
        orElse: () => const ProfileSettingsRouteArgs(),
      );
      return ProfileSettingsScreen(key: args.key, onLogout: args.onLogout);
    },
  );
}

class ProfileSettingsRouteArgs {
  const ProfileSettingsRouteArgs({this.key, this.onLogout});

  final Key? key;

  final Future<void> Function()? onLogout;

  @override
  String toString() {
    return 'ProfileSettingsRouteArgs{key: $key, onLogout: $onLogout}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ProfileSettingsRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// generated route for
/// [RegisterScreen]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
      : super(RegisterRoute.name, initialChildren: children);

  static const String name = 'RegisterRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const RegisterScreen();
    },
  );
}

/// generated route for
/// [ResetPasswordScreen]
class ResetPasswordRoute extends PageRouteInfo<void> {
  const ResetPasswordRoute({List<PageRouteInfo>? children})
      : super(ResetPasswordRoute.name, initialChildren: children);

  static const String name = 'ResetPasswordRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ResetPasswordScreen();
    },
  );
}

/// generated route for
/// [UserStatsScreen]
class UserStatsRoute extends PageRouteInfo<void> {
  const UserStatsRoute({List<PageRouteInfo>? children})
      : super(UserStatsRoute.name, initialChildren: children);

  static const String name = 'UserStatsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const UserStatsScreen();
    },
  );
}
