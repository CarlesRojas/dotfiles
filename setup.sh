#!/bin/bash
set -euxo pipefail

# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

sudo chsh "$(id -un)" --shell "/usr/bin/zsh"

# Install Oh My Zsh
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
    ZSH= sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi


# Install OMZ plugins idempotently
OMZ_PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

# zsh-autosuggestions
if [ ! -d "$OMZ_PLUGIN_DIR/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$OMZ_PLUGIN_DIR/zsh-autosuggestions"
else
    git -C "$OMZ_PLUGIN_DIR/zsh-autosuggestions" pull || true
fi

# zsh-syntax-highlighting
if [ ! -d "$OMZ_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$OMZ_PLUGIN_DIR/zsh-syntax-highlighting"
else
    git -C "$OMZ_PLUGIN_DIR/zsh-syntax-highlighting" pull || true
fi

# Install Oh My Bash
if [ ! -f "$HOME/.oh-my-bash/oh-my-bash.sh" ]; then
    rm -rf "$HOME/.oh-my-bash"
    OSH= bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended
fi

# Install zoxide (cd replacement)
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Install LSP servers for Claude Code
npm i -g pyright
npm i -g typescript-language-server typescript

# Set git identity in Codespaces (not applied locally)
if [ -n "${CODESPACES:-}" ]; then
    git config --global user.name "CarlesRojas"
    git config --global user.email "carles.rojas@rover.com"
fi

# Apply dotfiles (dot_claude/ -> ~/.claude/, etc.)
# In Codespaces $GITHUB_USER is set automatically; locally, apply from this repo's directory.
if [ -n "${GITHUB_USER:-}" ]; then
    "$HOME/.local/bin/chezmoi" init --apply "$GITHUB_USER"
else
    "$HOME/.local/bin/chezmoi" init --apply --source "$(cd "$(dirname "$0")" && pwd)"
fi

# Install Claude Code so the desktop app's SSH mode finds it on first connect
# (the app would otherwise install it itself). Native installer, goes to ~/.local/bin.
if ! command -v claude >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/claude" ]; then
    curl -fsSL https://claude.ai/install.sh | bash || echo "warning: Claude Code install failed; the desktop app will install it on first connect"
fi
