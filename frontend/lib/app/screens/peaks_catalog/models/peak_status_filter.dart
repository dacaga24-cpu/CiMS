// Aquest enum defineix els filtres disponibles segons l’estat personal del cim.
// S’utilitza des del catàleg i des del panell de filtres per mantenir
// les opcions d’estat separades del controller.
enum PeakStatusFilter {
  none,
  pending,
  completed,
  target,
  favorite,
}