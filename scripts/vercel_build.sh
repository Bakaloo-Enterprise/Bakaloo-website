#!/usr/bin/env bash
# Builds the Flutter web app on Vercel (which ships without Flutter).
# Wired up through vercel.json -> buildCommand.
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.9}"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Installing Flutter ${FLUTTER_VERSION}..."
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
fi

# Vercel builds run as root; silence git's ownership check for the SDK.
git config --global --add safe.directory '*' || true
flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version

# .env is gitignored but bundled as an asset, so generate it here.
# BASE_URL defaults to this deployment's own /api/v1 (proxied to the real
# API by the rewrite in vercel.json, which avoids CORS). Override it by
# setting BASE_URL / SOCKET_URL in the Vercel project's Environment Variables.
HOST="${VERCEL_PROJECT_PRODUCTION_URL:-${VERCEL_URL:-localhost}}"
if [ "${VERCEL_ENV:-production}" != "production" ] && [ -n "${VERCEL_URL:-}" ]; then
  HOST="$VERCEL_URL"
fi
cat > .env <<ENV
BASE_URL=${BASE_URL:-https://${HOST}/api/v1}
SOCKET_URL=${SOCKET_URL:-https://api.bakaloo.in}
ENV

flutter pub get
# Generated *.g.dart / *.freezed.dart files are gitignored.
flutter pub run build_runner build --delete-conflicting-outputs
flutter build web --release
