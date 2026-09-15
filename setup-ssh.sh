#!/bin/bash
# Run ONCE on your Mac. Lets you `ssh codespace` (and pick "codespace" as the SSH
# host in the Claude Code desktop app) to reach whichever Codespace you used most
# recently. New Codespaces get new names, but this alias never changes.
#
# Safe to re-run: it only appends to ~/.ssh/config if the alias is missing.
set -euo pipefail

# 1. gh installed and logged in (Codespace commands need the "codespace" scope;
#    gh prompts to add it on the first `gh codespace list` if it is missing).
command -v gh >/dev/null 2>&1 || brew install gh
gh auth status >/dev/null 2>&1 || gh auth login
GH="$(command -v gh)"

echo "Your Codespaces:"
"$GH" codespace list

# 2. SSH key that gh authorizes on the Codespace. `gh codespace ssh --config`
#    creates ~/.ssh/codespaces.auto if missing; fall back to ssh-keygen.
mkdir -p ~/.ssh && chmod 700 ~/.ssh
"$GH" codespace ssh --config >/dev/null 2>&1 || true
[ -f ~/.ssh/codespaces.auto ] || ssh-keygen -t ed25519 -N '' -f ~/.ssh/codespaces.auto

# 3. Stable alias. The ProxyCommand asks gh for the most recently used Codespace
#    every time you connect, so nothing has to be edited per Codespace.
CONFIG=~/.ssh/config
touch "$CONFIG" && chmod 600 "$CONFIG"
if ! grep -q '^Host codespace$' "$CONFIG"; then
cat >> "$CONFIG" <<CFG

# Added by dotfiles/setup-ssh.sh: "codespace" = your most recently used Codespace.
Host codespace
    User codespace
    ProxyCommand $GH codespace ssh -c "\$($GH codespace list --json name,lastUsedAt --jq 'sort_by(.lastUsedAt) | .[-1].name')" --stdio -- -i %d/.ssh/codespaces.auto
    IdentityFile ~/.ssh/codespaces.auto
    UserKnownHostsFile /dev/null
    StrictHostKeyChecking no
    LogLevel quiet
CFG
    echo "Added 'Host codespace' to $CONFIG"
else
    echo "'Host codespace' already in $CONFIG"
fi

# 4. Test
echo "Connecting..."
ssh codespace 'echo "connected to $CODESPACE_NAME"'
