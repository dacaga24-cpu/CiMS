import 'package:flutter/foundation.dart';

enum AppStartDestination {
  none,
  login,
  dashboard,
}

class AppStartController extends ChangeNotifier {
  AppStartController({
    required Future<bool> Function() hasSavedSession,
    this.minimumDisplayTime = const Duration(milliseconds: 1800),
  }) : _hasSavedSession = hasSavedSession;

  final Future<bool> Function() _hasSavedSession;
  final Duration minimumDisplayTime;

  AppStartDestination _destination = AppStartDestination.none;
  AppStartDestination get destination => _destination;

  bool _disposed = false;

  Future<void> initialize() async {
    await Future.delayed(minimumDisplayTime);

    if (_disposed) return;

    final hasSession = await _hasSavedSession();

    if (_disposed) return;

    _destination = hasSession
        ? AppStartDestination.dashboard
        : AppStartDestination.login;

    notifyListeners();
  }

  void consumeNavigation() {
    _destination = AppStartDestination.none;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}