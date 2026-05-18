#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

usage() {
  cat <<'EOF'
Usage:
  scripts/zsh.sh [options]

Installs the zsh layer:
  - Oh My Zsh
  - Powerlevel10k via Homebrew
  - zsh-autosuggestions
  - zsh-syntax-highlighting
  - managed ~/.zshrc block

EOF
  print_common_options
}

ensure_main_dependencies() {
  local args=()
  [[ "$DRY_RUN" == "1" ]] && args+=(--dry-run)

  if ! load_homebrew_env || ! command_exists git; then
    log "zsh module needs Homebrew and Git; running main module first."
    "$PROJECT_ROOT/scripts/main.sh" "${args[@]}"
    if ! load_homebrew_env; then
      [[ "$DRY_RUN" == "1" ]] || die "Homebrew is required for the zsh module."
    fi
  fi
}

install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    if force_enabled zsh; then
      log "Oh My Zsh exists; updating it with git pull."
      run_cmd git -C "$HOME/.oh-my-zsh" pull --ff-only
    else
      log "Skipping Oh My Zsh; already installed."
    fi
  else
    log "Installing Oh My Zsh."
    run_shell 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
  fi
}

install_powerlevel10k() {
  install_or_reinstall_brew_formula powerlevel10k zsh
}

clone_or_refresh_plugin() {
  local name="$1"
  local repo="$2"
  local target="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$name"

  if [[ -d "$target/.git" ]]; then
    if force_enabled zsh; then
      log "Refreshing zsh plugin: $name"
      run_cmd git -C "$target" pull --ff-only
    else
      log "Skipping $name; already installed."
    fi
  elif [[ -e "$target" ]]; then
    die "$target exists but is not a git repository. Move it away or run manually."
  else
    log "Installing zsh plugin: $name"
    [[ "$DRY_RUN" == "1" ]] || mkdir -p "$(dirname "$target")"
    run_cmd git clone "$repo" "$target"
  fi
}

install_zsh_plugins() {
  clone_or_refresh_plugin zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git
  clone_or_refresh_plugin zsh-syntax-highlighting https://github.com/zsh-users/zsh-syntax-highlighting.git
}

write_zsh_config() {
  write_managed_zshrc_block zsh <<'EOF'
# Oh My Zsh + prompt + plugins
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

if command -v brew >/dev/null 2>&1; then
  P10K_THEME="$(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme"
  [[ -r "$P10K_THEME" ]] && source "$P10K_THEME"
fi

[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
EOF
}

main() {
  parse_common_args zsh "$@"
  if [[ "$SHOW_HELP" == "1" ]]; then
    usage
    exit 0
  fi

  require_macos
  ensure_main_dependencies
  install_oh_my_zsh
  install_powerlevel10k
  install_zsh_plugins
  write_zsh_config
  log "zsh module complete."
}

main "$@"
