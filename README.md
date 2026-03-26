# Dotfiles

Personal dotfiles for GitHub Codespaces.

## What's included

- **Claude Code** — LSP plugins (Pyright, TypeScript, Swift) with pre-configured permissions
- **Oh My Zsh** — with zsh-autosuggestions, zsh-syntax-highlighting, and zoxide
- **Custom ZSH theme** — powerline-style prompt: `[time] [path] [git branch]` (pastel macaron palette)

## Setup

1. Push this repo to GitHub
2. Go to **GitHub Settings > Codespaces > Dotfiles**
3. Select this repository

Codespaces will automatically run `setup.sh` on creation.

## Structure

```
dotfiles/
├── setup.sh                              # Entry point for Codespaces
├── dot_zshrc                             → ~/.zshrc
├── dot_claude/
│   └── settings.json                     → ~/.claude/settings.json
└── dot_oh-my-zsh/custom/themes/
    └── carles.zsh-theme                  → ~/.oh-my-zsh/custom/themes/
```

Files prefixed with `dot_` are placed in `~/` by [chezmoi](https://www.chezmoi.io/) (e.g. `dot_zshrc` → `~/.zshrc`).
