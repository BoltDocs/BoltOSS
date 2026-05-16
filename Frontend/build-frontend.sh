#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# build swift-docc-render

DOCC_FRONTEND_DIR="$SCRIPT_DIR/swift-docc-render"
DOCC_DEST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/BoltFramework/BoltBrowserUI/Assets/swift-docc-render"

cd "$DOCC_FRONTEND_DIR"

nvm install || { echo "error: nvm install failed" >&2; exit 1; }
nvm use || { echo "error: nvm use failed" >&2; exit 1; }

npm install

BASE_URL="/" \
VUE_APP_TARGET="ide" \
npm run build

rsync -a --delete dist/ "$DOCC_DEST_DIR"

# build user-guides

USER_GUIDES_DIR="$SCRIPT_DIR/user-guides"
USER_GUIDES_DEST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/BoltFramework/BoltUserGuideUI/Resources/user-guides"

cd "$USER_GUIDES_DIR"

nvm install || { echo "error: nvm install failed" >&2; exit 1; }
nvm use || { echo "error: nvm use failed" >&2; exit 1; }

corepack enable && corepack install

pnpm install

pnpm build

rsync -a --delete dist/ "$USER_GUIDES_DEST_DIR"
