# buy-new-mac

> 中文版: [README.zh.md](README.zh.md)

A small, repeatable macOS bootstrap for a fresh Mac. It can be rerun safely, executed module by module, or run as a full setup.

## Modules

| Module | Script | Installs |
| --- | --- | --- |
| `main` | `scripts/main.sh` | Homebrew, Git |
| `zsh` | `scripts/zsh.sh` | Oh My Zsh, Powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting |
| `js` | `scripts/js.sh` | nvm, latest Node.js LTS, pnpm |
| `all` | `scripts/all.sh` | Runs `main`, `zsh`, and `js` in order |

## Quick Start

Run everything:

```bash
bash scripts/all.sh
```

Run one module:

```bash
bash scripts/main.sh
bash scripts/zsh.sh
bash scripts/js.sh
```

## Common Options

Dry run without changing the machine:

```bash
bash scripts/all.sh --dry-run
```

Force one module:

```bash
bash scripts/all.sh --force zsh
bash scripts/zsh.sh --force
```

Force every module:

```bash
bash scripts/all.sh --force-all
```

Run only selected modules:

```bash
bash scripts/all.sh --only main,zsh
```

Skip selected modules:

```bash
bash scripts/all.sh --skip js
```

## Fresh Mac Without Git

You do not need Git installed on the new Mac. This command uses the macOS built-in `curl` to download `bootstrap.sh` from GitHub, then `bootstrap.sh` downloads this repo as a `.tar.gz` archive and runs `scripts/all.sh`.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuicaLondon/buy-new-mac-/main/bootstrap.sh)"
```

You can pass options through to `scripts/all.sh`:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/SuicaLondon/buy-new-mac-/main/bootstrap.sh)" \
  -- --only main,zsh --dry-run
```

For a fork or another branch, override the repo or branch:

```bash
BUY_NEW_MAC_REPO=your-github-name/buy-new-mac \
BUY_NEW_MAC_BRANCH=main \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/your-github-name/buy-new-mac/main/bootstrap.sh)"
```

## What The Scripts Change

The scripts write managed blocks into `~/.zshrc`:

```zsh
# >>> buy-new-mac:main >>>
# ...
# <<< buy-new-mac:main <<<

# >>> buy-new-mac:zsh >>>
# ...
# <<< buy-new-mac:zsh <<<

# >>> buy-new-mac:js >>>
# ...
# <<< buy-new-mac:js <<<
```

The scripts only manage these marker blocks. Re-running a script replaces the matching block instead of appending duplicate content to `.zshrc`.

## Force Behavior

`--force` is intentionally conservative:

- `main`: runs `brew update` and reinstalls the Homebrew `git` formula.
- `zsh`: updates Oh My Zsh with `git pull`, reinstalls Powerlevel10k through Homebrew, and updates zsh plugins.
- `js`: reruns the nvm installer, installs latest Node.js LTS, and reactivates pnpm.

`--force` does not delete the whole Homebrew installation or the whole `~/.oh-my-zsh` directory, so manual configuration is not removed unexpectedly.

## Notes

- This project targets macOS.
- Homebrew may ask for a password or Xcode Command Line Tools during first install.
- Open a new terminal after setup, or run `source ~/.zshrc`.
- Run `p10k configure` after setup if you want to generate a fresh Powerlevel10k prompt config.
