# Carles custom theme — agnoster-inspired with powerline segments

# Colors
local C_TIME="#D4A5FF"
local C_PATH="#FFB5B5"
local C_GIT="#A5F0E4"
local C_BG="#000000"
local C_TEXT="#000000"
local C_OK="#A5F0E4"
local C_ERR="#FF5555"

# Separator: colored arrow then black arrow
# Usage: $(separator $prev_color $next_color)
separator() {
  echo "%{%K{$C_BG}%F{$1}%}%{%K{$2}%F{$C_BG}%}"
}

# Usage: $(separator_end $prev_color)
separator_end() {
  echo "%{%k%F{$1}%}%{%F{$C_BG}%}%{%f%}"
}

carles_git_prompt() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    local dirty=""
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      dirty=" ●"
    fi
    echo "$(separator $C_PATH $C_GIT)%{%F{$C_TEXT}%} $branch$dirty$(separator_end $C_GIT)"
  else
    echo "$(separator_end $C_PATH)"
  fi
}

PROMPT='%{%K{$C_TIME}%F{$C_TEXT}%} %* $(separator $C_TIME $C_PATH)%{%F{$C_TEXT}%} %1~ $(carles_git_prompt)%{%f%k%} '

RPROMPT='%(?.%{%F{$C_OK}%}✓.%{%F{$C_ERR}%}✗ %?) %{%f%}'
