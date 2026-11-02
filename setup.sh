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

# Agent tooling for Roverspaces / Codespaces (Linux only): what /implement needs to
# commit with the repo's hooks and to record videos and screenshots of the local app.
if [ "$(uname -s)" = "Linux" ]; then
    # pre-commit, so the web repo's git hooks run (also from worktrees) and nobody
    # needs --no-verify.
    if ! command -v pre-commit >/dev/null 2>&1; then
        if command -v uv >/dev/null 2>&1; then
            uv tool install pre-commit || warn "pre-commit install failed"
        else
            python3 -m pip install --user pre-commit \
                || python3 -m pip install --user --break-system-packages pre-commit \
                || warn "pre-commit install failed"
        fi
    fi

    # Playwright without its browsers: recordings use the Chrome already in the image
    # (/opt/google/chrome/chrome). Playwright still needs its own ffmpeg to record.
    if ! command -v playwright-core >/dev/null 2>&1; then
        npm i -g playwright-core || warn "playwright-core install failed"
    fi
    playwright-core install ffmpeg || warn "Playwright ffmpeg install failed"

    # A full ffmpeg on PATH to convert recordings to mp4: the system one if sudo works,
    # otherwise the static build from imageio-ffmpeg in its own venv.
    if ! command -v ffmpeg >/dev/null 2>&1; then
        if ! { sudo -n apt-get update -qq && sudo -n apt-get install -y -qq ffmpeg; }; then
            FFMPEG_VENV="$HOME/.local/share/imageio-ffmpeg"
            if python3 -m venv "$FFMPEG_VENV" && "$FFMPEG_VENV/bin/pip" install -q imageio-ffmpeg; then
                ln -sf "$("$FFMPEG_VENV/bin/python" -c 'import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())')" \
                    "$HOME/.local/bin/ffmpeg" || warn "could not link ffmpeg"
            else
                warn "ffmpeg install failed"
            fi
        fi
    fi
fi
