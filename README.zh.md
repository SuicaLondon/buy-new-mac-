# buy-new-mac

> English version: [README.md](README.md)

這是一組給新 Mac 使用的基礎環境安裝腳本。目標是可重複執行、可按模組單獨執行，也可以一鍵跑完整 setup。

## 模組

| 模組 | 腳本 | 安裝內容 |
| --- | --- | --- |
| `main` | `scripts/main.sh` | Homebrew、Git |
| `zsh` | `scripts/zsh.sh` | Oh My Zsh、Powerlevel10k、zsh-autosuggestions、zsh-syntax-highlighting |
| `js` | `scripts/js.sh` | nvm、最新 Node.js LTS、pnpm |
| `all` | `scripts/all.sh` | 依序執行 `main`、`zsh`、`js` |

## 快速開始

執行全部配置：

```bash
bash scripts/all.sh
```

單獨執行某個模組：

```bash
bash scripts/main.sh
bash scripts/zsh.sh
bash scripts/js.sh
```

## 常用參數

只預覽，不修改本機：

```bash
bash scripts/all.sh --dry-run
```

強制刷新某個模組：

```bash
bash scripts/all.sh --force zsh
bash scripts/zsh.sh --force
```

強制刷新所有模組：

```bash
bash scripts/all.sh --force-all
```

只跑指定模組：

```bash
bash scripts/all.sh --only main,zsh
```

跳過指定模組：

```bash
bash scripts/all.sh --skip js
```

## 新 Mac 沒有 Git 的執行方式

把這個 repo 推到 GitHub 後，新 Mac 即使還沒有 Git，也可以先用 `curl` 跑 bootstrap。把 `your-github-name` 換成你的 GitHub username：

```bash
BUY_NEW_MAC_REPO=your-github-name/buy-new-mac \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/your-github-name/buy-new-mac/main/bootstrap.sh)"
```

也可以把參數傳給 `scripts/all.sh`：

```bash
BUY_NEW_MAC_REPO=your-github-name/buy-new-mac \
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/your-github-name/buy-new-mac/main/bootstrap.sh)" \
  -- --only main,zsh --dry-run
```

## 腳本會修改什麼

腳本會在 `~/.zshrc` 寫入可管理的區塊：

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

腳本只管理這些 marker block。重複執行時會替換同名 block，不會一直往 `.zshrc` 追加重複內容。

## 強制刷新行為

`--force` 的設計偏保守：

- `main`：執行 `brew update`，並重新安裝 Homebrew 的 `git` formula。
- `zsh`：用 `git pull` 更新 Oh My Zsh，透過 Homebrew 重新安裝 Powerlevel10k，並更新 zsh plugins。
- `js`：重新執行 nvm installer，安裝最新 Node.js LTS，並重新啟用 pnpm。

`--force` 不會自動刪除整個 Homebrew 或整個 `~/.oh-my-zsh`，避免把手動配置一起刪掉。

## 注意事項

- 這個專案只針對 macOS。
- Homebrew 第一次安裝可能會要求密碼或安裝 Xcode Command Line Tools。
- 安裝完成後開一個新的 terminal，或者執行 `source ~/.zshrc`。
- 如果想重新配置 Powerlevel10k prompt，可以執行 `p10k configure`。
