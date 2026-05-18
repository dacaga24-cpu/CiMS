import 'package:flutter/material.dart';

enum AppScreenSize {
  compact,
  medium,
  expanded,
}

class AppResponsive {
  const AppResponsive._();

  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1200;

  static AppScreenSize screenSize(BuildContext context) {
    return screenSizeForWidth(MediaQuery.sizeOf(context).width);
  }

  static AppScreenSize screenSizeForWidth(double width) {
    if (width < compactBreakpoint) {
      return AppScreenSize.compact;
    }

    if (width < expandedBreakpoint) {
      return AppScreenSize.medium;
    }

    return AppScreenSize.expanded;
  }

  static bool isCompact(BuildContext context) {
    return screenSize(context) == AppScreenSize.compact;
  }

  static bool isMedium(BuildContext context) {
    return screenSize(context) == AppScreenSize.medium;
  }

  static bool isExpanded(BuildContext context) {
    return screenSize(context) == AppScreenSize.expanded;
  }

  static EdgeInsets pagePadding(
    BuildContext context, {
    double compactHorizontal = 16,
    double mediumHorizontal = 24,
    double expandedHorizontal = 32,
    double compactTop = 16,
    double mediumTop = 24,
    double expandedTop = 28,
    double compactBottom = 24,
    double mediumBottom = 32,
    double expandedBottom = 36,
  }) {
    switch (screenSize(context)) {
      case AppScreenSize.compact:
        return EdgeInsets.fromLTRB(
          compactHorizontal,
          compactTop,
          compactHorizontal,
          compactBottom,
        );
      case AppScreenSize.medium:
        return EdgeInsets.fromLTRB(
          mediumHorizontal,
          mediumTop,
          mediumHorizontal,
          mediumBottom,
        );
      case AppScreenSize.expanded:
        return EdgeInsets.fromLTRB(
          expandedHorizontal,
          expandedTop,
          expandedHorizontal,
          expandedBottom,
        );
    }
  }

  static double contentMaxWidth(BuildContext context) {
    switch (screenSize(context)) {
      case AppScreenSize.compact:
        return double.infinity;
      case AppScreenSize.medium:
        return 880;
      case AppScreenSize.expanded:
        return 1180;
    }
  }

  static double formMaxWidth(BuildContext context) {
    return isCompact(context) ? double.infinity : 540;
  }

  static int gridColumns(
    BuildContext context, {
    int compact = 1,
    int medium = 2,
    int expanded = 3,
  }) {
    switch (screenSize(context)) {
      case AppScreenSize.compact:
        return compact;
      case AppScreenSize.medium:
        return medium;
      case AppScreenSize.expanded:
        return expanded;
    }
  }
}

class ResponsiveConstrainedBox extends StatelessWidget {
  const ResponsiveConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? AppResponsive.contentMaxWidth(context),
        ),
        child: child,
      ),
    );
  }
}
