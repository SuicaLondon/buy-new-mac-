#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/main.sh [options]

Installs the main macOS base layer:
  - Homebrew
  - Git via Homebrew

EOF
  print_common_options
}

install_homebrew() {
  if load_homebrew_env; then
    if force_enabled main; then
      log "Homebrew is installed; running brew update for forced main module."
      run_cmd brew update
    else
      log "Skipping Homebrew; already installed."
    fi
  else
    log "Installing Homebrew."
    run_shell '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    if ! load_homebrew_env; then
      [[ "$DRY_RUN" == "1" ]] || die "Homebrew install finished, but brew is still not available in this shell."
    fi
  fi

  write_managed_zshrc_block main <<'EOF'
# Homebrew
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
EOF
}

install_git() {
  install_or_reinstall_brew_formula git main
}

main() {
  parse_common_args main "$@"
  if [[ "$SHOW_HELP" == "1" ]]; then
    usage
    exit 0
  fi

  require_macos
  install_homebrew
  install_git
  log "Main module complete."
}

main "$@"
