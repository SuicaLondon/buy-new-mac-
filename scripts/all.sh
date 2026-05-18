#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/all.sh [options]

Runs every setup module in dependency order:
  1. main
  2. zsh
  3. js

Extra all-module options:
  --only a,b        Run only selected modules: main,zsh,js.
  --skip a,b        Skip selected modules.

EOF
  print_common_options
}

csv_has() {
  local csv="$1"
  local needle="$2"
  local item
  local old_ifs="$IFS"
  IFS=","
  for item in $csv; do
    [[ "$item" == "$needle" ]] && {
      IFS="$old_ifs"
      return 0
    }
  done
  IFS="$old_ifs"
  return 1
}

main() {
  local only=""
  local skip=""
  local pass_args=()
  local module
  local modules=(main zsh js)

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --only)
        [[ $# -gt 1 ]] || die "--only requires a comma-separated module list."
        only="$2"
        shift
        ;;
      --only=*)
        only="${1#--only=}"
        ;;
      --skip)
        [[ $# -gt 1 ]] || die "--skip requires a comma-separated module list."
        skip="$2"
        shift
        ;;
      --skip=*)
        skip="${1#--skip=}"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        pass_args+=("$1")
        ;;
    esac
    shift
  done

  require_macos
  for module in "${modules[@]}"; do
    if [[ -n "$only" ]] && ! csv_has "$only" "$module"; then
      log "Skipping $module; not in --only list."
      continue
    fi
    if [[ -n "$skip" ]] && csv_has "$skip" "$module"; then
      log "Skipping $module; requested by --skip."
      continue
    fi

    log "Running module: $module"
    "$SCRIPT_DIR/$module.sh" "${pass_args[@]}"
  done
  log "All requested modules complete."
}

main "$@"
