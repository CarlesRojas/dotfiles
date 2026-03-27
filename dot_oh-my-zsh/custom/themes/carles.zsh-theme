# Carles custom theme — agnoster-inspired with powerline segments

# Disable default virtualenv prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Colors
local C_FIRST="#558CB6"
local C_SECOND="#86BBD8"
local C_THIRD="#758E4F"
local C_FOURTH="#C97A41"

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

carles_venv_prompt() {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    local venv_name=$(basename "$VIRTUAL_ENV")
    echo "$(separator $C_FIRST $C_SECOND)%{%F{$C_BLACK}%}  $venv_name "
  fi
}

carles_git_prompt() {
  local prev_color=$C_FIRST
  [[ -n "$VIRTUAL_ENV" ]] && prev_color=$C_SECOND

  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -n "$branch" ]]; then
    local dirty=""
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      dirty=" ●"
    fi
    echo "$(separator $prev_color $C_THIRD)%{%F{$C_BLACK}%} 󰉖 %1~ $(separator $C_THIRD $C_FOURTH)%{%F{$C_BLACK}%}  $branch$dirty "
  else
    echo "$(separator $prev_color $C_FOURTH)%{%F{$C_BLACK}%} 󰉖 %1~ "
  fi
}

PROMPT='%{%K{$C_FIRST}%F{$C_BLACK}%}  %* $(carles_venv_prompt)$(carles_git_prompt)$(separator_end $C_FOURTH)%{%f%k%} %(?.%{%F{$C_OK}%}✓.%{%F{$C_ERR}%}✗%{%f%}) '

RPROMPT=''
