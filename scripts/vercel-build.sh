#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Checking required Vercel environment variables"
: "${MCQ_API_URL:?Missing MCQ_API_URL environment variable}"
: "${PUSH_API_URL:?Missing PUSH_API_URL environment variable}"
: "${FIREBASE_VAPID_KEY:?Missing FIREBASE_VAPID_KEY environment variable}"

echo "==> Preparing isolated Python environment"
PYTHON_ENV="${HOME}/atlas-academy-build-venv"
if [ ! -x "$PYTHON_ENV/bin/python" ]; then
  python3 -m venv "$PYTHON_ENV"
fi
source "$PYTHON_ENV/bin/activate"
echo "==> Installing Python asset-generation dependencies"
python -m pip install --upgrade pip Pillow CairoSVG rdkit

echo "==> Installing Flutter stable SDK"
FLUTTER_DIR="${HOME}/flutter"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
flutter --version

echo "==> Preparing Atlas Academy launcher artwork"
python3 scripts/prepare_launcher_icons.py

echo "==> Generating pharmacology molecular models"
python3 scripts/build_pharmacology_molecular_models.py

echo "==> Generating pharmacology drug conformers"
python3 scripts/build_pharmacology_drug_conformers.py

echo "==> Installing Flutter packages"
flutter pub get

echo "==> Building The Atlas Academy web app"
flutter build web --release \
  --dart-define=MCQ_API_URL="$MCQ_API_URL" \
  --dart-define=PUSH_API_URL="$PUSH_API_URL" \
  --dart-define=FIREBASE_VAPID_KEY="$FIREBASE_VAPID_KEY"

echo "==> Verifying generated web files"
test -s build/web/index.html
test -s build/web/firebase-messaging-sw.js
test -s build/web/download/index.html
test -s build/web/download/atlas_academy_logo.svg

echo "==> Atlas Academy web build completed successfully"
