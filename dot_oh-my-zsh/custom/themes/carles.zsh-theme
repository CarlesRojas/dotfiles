# Carles custom theme — agnoster-inspired with powerline segments
# Layout: [time]  [path]  [git branch]  ❯

PROMPT='%{%K{#ADFF2F}%F{#1E1E2E}%} %* %{%F{#ADFF2F}%K{#FF1493}%}%{%F{#FFFFFF}%} %~ %{%F{#FF1493}%}$(carles_git_prompt)%{%f%k%} '

carles_git_prompt() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    local dirty=""
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      dirty=" ●"
    fi
    echo "%{%K{#00BFFF}%}%{%F{#1E1E2E}%}  $branch$dirty %{%F{#00BFFF}%k%}%{%f%}"
  else
    echo "%{%k%}%{%f%}"
  fi
}

RPROMPT='%(?.%{%F{#ADFF2F}%}✓.%{%F{#FF5555}%}✗ %?) %{%f%}'
