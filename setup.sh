#!/bin/bash
set -euxo pipefail

# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"

# Install Oh My Zsh
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    rm -rf "$HOME/.oh-my-zsh"
    ZSH= sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Set default shell to zsh
sudo chsh "$(id -un)" --shell "/usr/bin/zsh"

# Install OMZ plugins
git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

# Install zoxide (cd replacement)
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh

# Install LSP servers for Claude Code
npm i -g pyright
npm i -g typescript-language-server typescript

# Apply dotfiles (dot_claude/ -> ~/.claude/, etc.)
"$HOME/.local/bin/chezmoi" init --apply "$GITHUB_USER"
