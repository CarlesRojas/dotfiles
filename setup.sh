#!/bin/bash
# No `set -e`: one failed step (a blocked download, a missing shell) must not stop
# the rest of the setup. Each step warns and the script carries on.
set -uxo pipefail

warn() { echo "warning: $*" >&2; }

# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" || warn "chezmoi install failed"

# Switch the login shell to zsh, only if zsh is installed
if [ -x /usr/bin/zsh ]; then
    sudo chsh "$(id -un)" --shell "/usr/bin/zsh" || warn "could not switch the login shell to zsh"
else
    warn "/usr/bin/zsh not found; keeping the current shell"
fi

# Install Oh My Zsh
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
    ZSH= sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended \
        || warn "Oh My Zsh install failed"
fi

# Install OMZ plugins idempotently
OMZ_PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

# zsh-autosuggestions
if [ ! -d "$OMZ_PLUGIN_DIR/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$OMZ_PLUGIN_DIR/zsh-autosuggestions" \
        || warn "zsh-autosuggestions install failed"
else
    git -C "$OMZ_PLUGIN_DIR/zsh-autosuggestions" pull || true
fi

# zsh-syntax-highlighting
if [ ! -d "$OMZ_PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$OMZ_PLUGIN_DIR/zsh-syntax-highlighting" \
        || warn "zsh-syntax-highlighting install failed"
else
    git -C "$OMZ_PLUGIN_DIR/zsh-syntax-highlighting" pull || true
fi

# Install Oh My Bash
if [ ! -f "$HOME/.oh-my-bash/oh-my-bash.sh" ]; then
    rm -rf "$HOME/.oh-my-bash"
    OSH= bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" "" --unattended \
        || warn "Oh My Bash install failed"
fi

# Install zoxide (cd replacement)
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || warn "zoxide install failed"

# Install LSP servers for Claude Code
npm i -g pyright || warn "pyright install failed"
npm i -g typescript-language-server typescript || warn "TypeScript LSP install failed"

# Set git identity in Codespaces (not applied locally)
if [ -n "${CODESPACES:-}" ]; then
    git config --global user.name "CarlesRojas"
    git config --global user.email "carles.rojas@rover.com"
fi

# Apply dotfiles (dot_zshrc -> ~/.zshrc, etc.) from this checkout. Codespaces clones
# the repo to /workspaces/.codespaces/.persistedshare/dotfiles and runs this script from
# there, so a second clone via GitHub is not needed and cannot go stale. --force overwrites
# files changed since the last apply without prompting (Codespace creation has no terminal).
if [ -x "$HOME/.local/bin/chezmoi" ]; then
    "$HOME/.local/bin/chezmoi" init --apply --force --source "$(cd "$(dirname "$0")" && pwd)" \
        || warn "chezmoi apply failed"
else
    warn "chezmoi is missing; dotfiles were not applied"
fi

# Install Claude Code so the desktop app's SSH mode finds it on first connect
# (the app would otherwise install it itself). Native installer, goes to ~/.local/bin.
if ! command -v claude >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/claude" ]; then
    curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install failed; the desktop app will install it on first connect"
fi

# T3 Code over SSH (Linux remotes only: Roverspaces, Codespaces).
# T3 launches `claude` from a non-interactive shell that doesn't load ~/.local/bin,
# so link it somewhere on the default PATH, and preinstall the T3 server so the
# first connection from the desktop app doesn't have to install it.
if [ "$(uname -s)" = "Linux" ]; then
    if [ -x "$HOME/.local/bin/claude" ]; then
        sudo -n ln -sf "$HOME/.local/bin/claude" /usr/local/bin/claude \
            || warn "could not link claude into /usr/local/bin"
    fi
    if ! command -v t3 >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/t3" ]; then
        curl -fsSL https://t3.codes/install.sh | sh || warn "T3 Code server install failed"
    fi
fi
