#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCC_FRONTEND_DIR="$SCRIPT_DIR/swift-docc-render"
DEST_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/BoltFramework/BoltBrowserUI/Assets/swift-docc-render"

cd "$DOCC_FRONTEND_DIR"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

nvm use || { echo "error: nvm use failed" >&2; exit 1; }

npm install

BASE_URL="/" \
VUE_APP_TARGET="ide" \
npm run build

rsync -a --delete dist/ "$DEST_DIR"
