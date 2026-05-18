#!/usr/bin/env bash

set -euo pipefail

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$COMMON_DIR/.." && pwd)"

DRY_RUN="${DRY_RUN:-0}"
FORCE_ALL="${FORCE_ALL:-0}"
ASSUME_YES="${ASSUME_YES:-0}"
SHOW_HELP=0
POSITIONAL_ARGS=()
FORCE_MODULES=()

log() {
  printf '\033[1;34m[buy-new-mac]\033[0m %s\n' "$*"
}

warn() {
  printf '\033[1;33m[warn]\033[0m %s\n' "$*" >&2
}

die() {
  printf '\033[1;31m[error]\033[0m %s\n' "$*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || die "This setup is intended for macOS only."
}

add_force_module() {
  local raw="$1"
  local item
  local old_ifs="$IFS"
  IFS=","
  for item in $raw; do
    [[ -n "$item" ]] && FORCE_MODULES+=("$item")
  done
  IFS="$old_ifs"
}

parse_common_args() {
  local default_force_module="${1:-}"
  shift || true

  POSITIONAL_ARGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        ;;
      --force-all)
        FORCE_ALL=1
        ;;
      --force)
        if [[ $# -gt 1 && "${2:-}" != --* ]]; then
          add_force_module "$2"
          shift
        elif [[ -n "$default_force_module" ]]; then
          add_force_module "$default_force_module"
        else
          FORCE_ALL=1
        fi
        ;;
      --force=*)
        add_force_module "${1#--force=}"
        ;;
      -y|--yes)
        ASSUME_YES=1
        ;;
      -h|--help)
        SHOW_HELP=1
        ;;
      *)
        POSITIONAL_ARGS+=("$1")
        ;;
    esac
    shift
  done
}

force_enabled() {
  local module="$1"
  local item

  [[ "$FORCE_ALL" == "1" ]] && return 0
  for item in "${FORCE_MODULES[@]:-}"; do
    [[ "$item" == "$module" ]] && return 0
  done
  return 1
}

run_cmd() {
  if [[ "$DRY_RUN" == "1" ]]; then
    log "dry-run: $*"
  else
    "$@"
  fi
}

run_shell() {
  local command_text="$1"

  if [[ "$DRY_RUN" == "1" ]]; then
    log "dry-run: $command_text"
  else
    bash -c "$command_text"
  fi
}

brew_path() {
  if command_exists brew; then
    command -v brew
  elif [[ -x /opt/homebrew/bin/brew ]]; then
    printf '%s\n' /opt/homebrew/bin/brew
  elif [[ -x /usr/local/bin/brew ]]; then
    printf '%s\n' /usr/local/bin/brew
  else
    return 1
  fi
}

load_homebrew_env() {
  local brew_bin
  brew_bin="$(brew_path)" || return 1
  eval "$("$brew_bin" shellenv)"
}

require_brew() {
  if ! load_homebrew_env; then
    [[ "$DRY_RUN" == "1" ]] && return 0
    die "Homebrew is not available. Run scripts/main.sh first."
  fi
}

brew_formula_installed() {
  local formula="$1"
  if ! load_homebrew_env; then
    return 1
  fi
  brew list --formula "$formula" >/dev/null 2>&1
}

install_or_reinstall_brew_formula() {
  local formula="$1"
  local module="${2:-$formula}"

  if ! load_homebrew_env; then
    if [[ "$DRY_RUN" == "1" ]]; then
      log "dry-run: brew install $formula"
      return 0
    fi
    die "Homebrew is not available. Run scripts/main.sh first."
  fi

  if brew_formula_installed "$formula"; then
    if force_enabled "$module"; then
      log "Reinstalling Homebrew formula: $formula"
      run_cmd brew reinstall "$formula"
    else
      log "Skipping $formula; already installed."
    fi
  else
    log "Installing Homebrew formula: $formula"
    run_cmd brew install "$formula"
  fi
}

write_managed_zshrc_block() {
  local block_name="$1"
  local file="${ZSHRC:-$HOME/.zshrc}"
  local begin="# >>> buy-new-mac:${block_name} >>>"
  local end="# <<< buy-new-mac:${block_name} <<<"
  local tmp
  local content

  content="$(cat)"
  tmp="$(mktemp)"

  if [[ -f "$file" ]]; then
    awk -v begin="$begin" -v end="$end" '
      $0 == begin { skip = 1; next }
      $0 == end { skip = 0; next }
      skip != 1 { print }
    ' "$file" > "$tmp"
  else
    : > "$tmp"
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    log "dry-run: would update $file block $block_name"
    rm -f "$tmp"
    return 0
  fi

  mkdir -p "$(dirname "$file")"
  {
    cat "$tmp"
    printf '\n%s\n' "$begin"
    printf '%s\n' "$content"
    printf '%s\n' "$end"
  } > "$file"
  rm -f "$tmp"
}

print_common_options() {
  cat <<'EOF'
Common options:
  --dry-run          Print what would run without changing the machine.
  --force           Force the current module when running a module script.
  --force NAME      Force one module by name: main, zsh, or js.
  --force=a,b       Force several modules by comma-separated name.
  --force-all       Force every module.
  -h, --help        Show help.
EOF
}
