# Dotfiles

Personal dotfiles for Roverspaces, GitHub Codespaces and local machines.

## What's included

- **LSP servers for Claude Code** — Pyright and the TypeScript language server, installed globally with npm
- **Oh My Zsh** — with zsh-autosuggestions, zsh-syntax-highlighting, and zoxide
- **Custom ZSH theme** — powerline-style prompt: `[time] [path] [git branch]` (pastel macaron palette)

- **Agent tooling for Roverspaces** — `pre-commit`, Playwright (using the image's Chrome), and a full `ffmpeg` for mp4 conversion, so `/implement` can commit with the repo's hooks and record the local app
- **`dc-worktree`** — points the dev stack's `web` container at the current git worktree (`dc-worktree up`), and back to the main checkout (`dc-worktree release`). A lock lets only one worktree hold `web` at a time; others wait their turn. `dc-worktree status` shows what it serves and who holds it

## Setup

### GitHub Codespaces

1. Push this repo to GitHub
2. Go to **GitHub Settings > Codespaces > Dotfiles** (github.com/settings/codespaces)
3. Tick **Automatically install dotfiles** and select this repository

Codespaces clones this repo into every new Codespace and runs `setup.sh` on creation. Dotfiles only run when a Codespace is created, so existing Codespaces need a rebuild or a manual run:

```bash
cd /workspaces/.codespaces/.persistedshare/dotfiles && git pull && ./setup.sh
```

The install log is at `/workspaces/.codespaces/.persistedshare/dotfiles-install.log`.

### Local machine

```bash
git clone https://github.com/CarlesRojas/dotfiles ~/dotfiles
cd ~/dotfiles
bash setup.sh
```

Then authenticate Claude Code with your Claude Enterprise account:

```bash
claude auth login
```

This opens a browser — sign in with your work SSO through claude.ai. No API key needed.

### Roverspaces

Add this repo as your dotfiles repo in Roverspaces **Settings**.

`setup.sh` does not stop on the first error: a failed step prints a `warning:` line and the rest of the setup still runs.

## Connect from the Claude Code desktop app over SSH

New Codespaces get new names, so the host entries that `gh codespace ssh --config` writes change every time. Instead, run this once on your Mac:

```bash
./setup-ssh.sh
```

It installs and logs in `gh` if needed, creates the `~/.ssh/codespaces.auto` key, and adds a `Host codespace` entry to `~/.ssh/config`. That entry asks `gh` for your most recently used Codespace each time you connect, so it never needs editing. In the Claude Code desktop app add an SSH connection with host `codespace` and leave port and identity file empty. From a terminal, `ssh codespace` does the same.

`setup.sh` also pre-installs Claude Code on the Codespace; the desktop app would otherwise install it on first connect.

## Claude Code settings and skills

This repo does not manage `~/.claude/`. Claude Code settings, skills and plugins come from [claude-sync](https://github.com/roverdotcom/claude-sync), which copies your Mac's setup into Roverspaces workspaces and Codespaces:

```bash
uv tool install git+https://github.com/roverdotcom/claude-sync.git
claude-sync login
```

## Structure

```
dotfiles/
├── setup.sh                              # Entry point for Roverspaces, Codespaces and local
├── setup-ssh.sh                          # Run once on the Mac: stable `ssh codespace` alias
├── dot_zshrc                             → ~/.zshrc
├── dot_bashrc                            → ~/.bashrc
├── dot_local/bin/executable_dc-worktree  → ~/.local/bin/dc-worktree
├── .chezmoiignore                        # Keeps README.md and the setup scripts out of ~
├── dot_oh-my-bash/custom/themes/carles/
│   └── carles.theme.sh                   → ~/.oh-my-bash/custom/themes/carles/
└── dot_oh-my-zsh/custom/themes/
    └── carles.zsh-theme                  → ~/.oh-my-zsh/custom/themes/
```

Files prefixed with `dot_` are placed in `~/` by [chezmoi](https://www.chezmoi.io/) (e.g. `dot_zshrc` → `~/.zshrc`).
