#!/usr/bin/env bash

set -euo pipefail

DEFAULT_REPO="SuicaLondon/buy-new-mac-"
REPO="${BUY_NEW_MAC_REPO:-$DEFAULT_REPO}"
BRANCH="${BUY_NEW_MAC_BRANCH:-main}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || printf '.')"

if [[ -f "$SCRIPT_DIR/bootstrap.sh" && -x "$SCRIPT_DIR/scripts/all.sh" ]]; then
  exec "$SCRIPT_DIR/scripts/all.sh" "$@"
fi

TMP_DIR="$(mktemp -d)"
ARCHIVE_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

printf '[buy-new-mac] downloading %s\n' "$ARCHIVE_URL"
curl -fsSL "$ARCHIVE_URL" | tar -xz -C "$TMP_DIR"

PROJECT_DIR="$TMP_DIR/$(basename "$REPO")-$BRANCH"
exec "$PROJECT_DIR/scripts/all.sh" "$@"
