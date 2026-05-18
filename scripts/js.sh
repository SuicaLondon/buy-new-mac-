#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/js.sh [options]

Installs the JavaScript layer:
  - nvm
  - latest Node.js LTS through nvm
  - pnpm through corepack, falling back to npm
  - managed ~/.zshrc block

EOF
  print_common_options
}

ensure_git_for_nvm() {
  local args=()
  [[ "$DRY_RUN" == "1" ]] && args+=(--dry-run)

  if ! command_exists git; then
    log "js module needs Git for nvm; running main module first."
    "$PROJECT_ROOT/scripts/main.sh" "${args[@]}"
  fi
}

load_nvm_if_available() {
  export NVM_DIR="$HOME/.nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
}

install_nvm() {
  if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    if force_enabled js; then
      log "nvm exists; rerunning the official installer to update it."
      run_shell 'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
    else
      log "Skipping nvm; already installed."
    fi
  else
    log "Installing nvm."
    run_shell 'curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
  fi

  load_nvm_if_available
}

install_node_lts() {
  load_nvm_if_available
  if ! command_exists nvm; then
    warn "nvm is not loaded in this shell; skipping Node.js LTS install."
    return 0
  fi

  log "Installing or updating latest Node.js LTS with nvm."
  if [[ "$DRY_RUN" == "1" ]]; then
    log "dry-run: nvm install --lts && nvm alias default 'lts/*'"
  else
    nvm install --lts
    nvm alias default 'lts/*'
  fi
}

install_pnpm() {
  load_nvm_if_available
  if command_exists pnpm && ! force_enabled js; then
    log "Skipping pnpm; already installed."
    return 0
  fi

  if command_exists corepack; then
    log "Installing pnpm with corepack."
    run_cmd corepack enable
    run_cmd corepack prepare pnpm@latest --activate
  elif command_exists npm; then
    log "Installing pnpm with npm fallback."
    run_cmd npm install -g pnpm
  else
    warn "Neither corepack nor npm is available; pnpm was not installed."
  fi
}

write_js_config() {
  write_managed_zshrc_block js <<'EOF'
# nvm
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
EOF
}

main() {
  parse_common_args js "$@"
  if [[ "$SHOW_HELP" == "1" ]]; then
    usage
    exit 0
  fi

  require_macos
  ensure_git_for_nvm
  install_nvm
  install_node_lts
  install_pnpm
  write_js_config
  log "JavaScript module complete."
}

main "$@"
