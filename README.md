# Dotfiles

Personal dotfiles for GitHub Codespaces and local machines.

## What's included

- **Claude Code** — LSP plugins (Pyright, TypeScript, Swift) with pre-configured permissions, connected to Claude Enterprise via claude.ai OAuth
- **Claude Code personal skills** — `dot_claude/skills/` is copied to `~/.claude/skills/`, so personal skills are available in every Codespace without committing them to a project repo
- **Oh My Zsh** — with zsh-autosuggestions, zsh-syntax-highlighting, and zoxide
- **Custom ZSH theme** — powerline-style prompt: `[time] [path] [git branch]` (pastel macaron palette)

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

## Connect from the Claude Code desktop app over SSH

New Codespaces get new names, so the host entries that `gh codespace ssh --config` writes change every time. Instead, run this once on your Mac:

```bash
./setup-ssh.sh
```

It installs and logs in `gh` if needed, creates the `~/.ssh/codespaces.auto` key, and adds a `Host codespace` entry to `~/.ssh/config`. That entry asks `gh` for your most recently used Codespace each time you connect, so it never needs editing. In the Claude Code desktop app add an SSH connection with host `codespace` and leave port and identity file empty. From a terminal, `ssh codespace` does the same.

`setup.sh` also pre-installs Claude Code on the Codespace; the desktop app would otherwise install it on first connect.

## Claude Code skills

Personal skills live at `~/.claude/skills/<skill-name>/SKILL.md` on the machine where Claude Code runs. To ship them to Codespaces, copy each skill folder from your Mac into `dot_claude/skills/`:

```bash
cp -R ~/.claude/skills/<skill-name> dot_claude/skills/
```

chezmoi copies `dot_claude/skills/` to `~/.claude/skills/` when `setup.sh` runs. Only files present in this repo are written; other files in `~/.claude/` are left alone. Skills committed in a project's own `.claude/skills/` are unaffected and load alongside these.

## Structure

```
dotfiles/
├── setup.sh                              # Entry point for Codespaces and local
├── setup-ssh.sh                          # Run once on the Mac: stable `ssh codespace` alias
├── dot_zshrc                             → ~/.zshrc
├── .chezmoiignore                        # Keeps README.md and the setup scripts out of ~
├── dot_claude/
│   ├── settings.json                     → ~/.claude/settings.json
│   └── skills/<skill-name>/SKILL.md      → ~/.claude/skills/<skill-name>/SKILL.md
└── dot_oh-my-zsh/custom/themes/
    └── carles.zsh-theme                  → ~/.oh-my-zsh/custom/themes/
```

Files prefixed with `dot_` are placed in `~/` by [chezmoi](https://www.chezmoi.io/) (e.g. `dot_zshrc` → `~/.zshrc`).
