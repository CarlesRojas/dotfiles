# Carles custom theme — agnoster-inspired with powerline segments

# Colors
local C_TIME="#D4A5FF"
local C_PATH="#FFB5B5"
local C_GIT="#A5F0E4"
local C_BLACK="#000000"
local C_OK="#A5F0E4"
local C_ERR="#FF5555"

# Separator: colored arrow on black bg, then black arrow on next bg
# Usage: $(separator $prev_color $next_color)
separator() {
  echo "%{%K{$C_BLACK}%F{$1}%}%{%K{$2}%F{$C_BLACK}%}"
}

# Usage: $(separator_end $prev_color)
separator_end() {
  echo "%{%k%F{$1}%}%{%f%}"
}

carles_git_prompt() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    local dirty=""
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      dirty=" ●"
    fi
    echo "$(separator $C_TIME $C_GIT)%{%F{$C_BLACK}%} $branch$dirty $(separator $C_GIT $C_PATH)"
  else
    echo "$(separator $C_TIME $C_PATH)"
  fi
}

PROMPT='%{%K{$C_TIME}%F{$C_BLACK}%} %* $(carles_git_prompt)%{%F{$C_BLACK}%} %1~ $(separator_end $C_PATH)%{%f%k%} '

RPROMPT='%(?.%{%F{$C_OK}%}✓.%{%F{$C_ERR}%}✗ %?) %{%f%}'
