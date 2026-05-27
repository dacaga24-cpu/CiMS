import 'package:flutter/material.dart';

// Aquest enum defineix les mides generals de pantalla que contempla l’aplicació.
// Permet adaptar la interfície segons si s’està utilitzant en mòbil, tauleta o pantalla gran.
enum AppScreenSize {
  compact,
  medium,
  expanded,
}

// Aquesta classe centralitza les regles responsives de l’aplicació.
// Evita repetir càlculs de mida, marges i columnes en diferents pantalles.
class AppResponsive {
  const AppResponsive._();

  // Aquests valors defineixen els punts de canvi entre formats de pantalla.
  // Serveixen per aplicar layouts diferents segons l’amplada disponible.
  static const double compactBreakpoint = 600;
  static const double expandedBreakpoint = 1200;

  // Retorna la mida de pantalla actual a partir del context.
  // Permet que qualsevol widget adapti el seu comportament de manera coherent.
  static AppScreenSize screenSize(BuildContext context) {
    return screenSizeForWidth(MediaQuery.sizeOf(context).width);
  }

  // Calcula la categoria de pantalla a partir d’una amplada concreta.
  // És útil per reutilitzar la mateixa lògica fora del context visual directe.
  static AppScreenSize screenSizeForWidth(double width) {
    if (width < compactBreakpoint) {
      return AppScreenSize.compact;
    }

    if (width < expandedBreakpoint) {
      return AppScreenSize.medium;
    }

    return AppScreenSize.expanded;
  }

  // Indica si la pantalla actual correspon al format compacte.
  static bool isCompact(BuildContext context) {
    return screenSize(context) == AppScreenSize.compact;
  }

  // Indica si la pantalla actual correspon al format mitjà.
  static bool isMedium(BuildContext context) {
    return screenSize(context) == AppScreenSize.medium;
  }

  // Indica si la pantalla actual correspon al format ampliat.
  static bool isExpanded(BuildContext context) {
    return screenSize(context) == AppScreenSize.expanded;
  }

  // Retorna el marge principal d’una pantalla segons la mida disponible.
  // Permet mantenir proporcions adequades en mòbil, tauleta i escriptori.
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

  // Retorna l’amplada màxima recomanada per al contingut principal.
  // Evita que les pantalles grans estirin massa els blocs visuals.
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

  // Retorna l’amplada màxima recomanada per a formularis.
  // Manté els camps còmodes de llegir en pantalles mitjanes i grans.
  static double formMaxWidth(BuildContext context) {
    return isCompact(context) ? double.infinity : 540;
  }

  // Retorna el nombre de columnes recomanat per a graelles.
  // Permet adaptar l’organització visual segons l’espai disponible.
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

// Aquest widget limita l’amplada del contingut segons les regles responsives.
// Serveix per centrar pantalles i evitar layouts massa estesos en escriptori.
class ResponsiveConstrainedBox extends StatelessWidget {
  const ResponsiveConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  // Aquestes dades defineixen el contingut, l’amplada màxima i l’alineació del bloc.
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