// Aquest enum agrupa els avisos puntuals que els controllers del catàleg
// i del mapa volen comunicar a les seves pantalles, sense que la lògica
// de càrrega depengui del context visual. La pantalla els transforma en
// snackbars i, un cop mostrats, crida consumeFeedback() perquè no es
// dispari el mateix avís dos cops.
enum PeaksFeedback {
  // Cap avís pendent. Estat per defecte i resultat després de
  // consumeFeedback().
  none,

  // El backend ha retornat WEATHER_PROVIDER_UNAVAILABLE mentre el
  // filtre meteorològic estava actiu. L'usuari veu un snackbar amb
  // l'opció de treure el filtre per recuperar el catàleg complet.
  weatherProviderUnavailable,
}
