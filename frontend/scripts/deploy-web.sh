#!/usr/bin/env bash
# Aquest script construeix la web de CiMS i la desplega a Firebase Hosting.
#
# Important: la flag `--no-tree-shake-icons` és imprescindible. El paquet
# material_symbols_icons inclou un font de Material Symbols i el
# tree-shaker per defecte de Flutter web n'elimina la majoria de glifos
# en builds de producció, deixant la card meteorològica amb la majoria
# d'iconos en blanc. Documentat al README del package i comprovat en
# producció el 2026-05.
#
# Requisits (només la primera vegada):
#   * Tenir firebase-tools instal·lat (npm install -g firebase-tools).
#   * Haver fet `firebase login` amb un compte amb accés al projecte
#     cims-web-84caf.
#
# Ús: ./scripts/deploy-web.sh           (build + deploy a Hosting)
#     ./scripts/deploy-web.sh --build   (només build, sense desplegar)

set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> Construint la web de CiMS amb tree-shake d'iconos desactivat..."
flutter build web --release --no-tree-shake-icons

if [[ "${1:-}" == "--build" ]]; then
  echo "==> Build acabat a build/web/. Sortint sense desplegar."
  exit 0
fi

echo "==> Desplegant a Firebase Hosting..."
firebase deploy --only hosting

echo "==> Desplegament finalitzat."
