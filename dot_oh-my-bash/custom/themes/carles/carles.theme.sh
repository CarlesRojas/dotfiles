#!/usr/bin/env bash
# Carles custom theme — agnoster-inspired with powerline segments (bash port)

export VIRTUAL_ENV_DISABLE_PROMPT=1

# Color codes using \[\e[...m\] — bash interprets these natively in PS1
# 24-bit format: \e[38;2;R;G;Bm (fg) / \e[48;2;R;G;Bm (bg)
_BG_FIRST='\[\e[48;2;85;140;182m\]'
_BG_SECOND='\[\e[48;2;134;187;216m\]'
_BG_THIRD='\[\e[48;2;117;142;79m\]'
_BG_FOURTH='\[\e[48;2;201;122;65m\]'
_BG_BLACK='\[\e[48;2;0;0;0m\]'

_FG_FIRST='\[\e[38;2;85;140;182m\]'
_FG_SECOND='\[\e[38;2;134;187;216m\]'
_FG_THIRD='\[\e[38;2;117;142;79m\]'
_FG_FOURTH='\[\e[38;2;201;122;65m\]'
_FG_BLACK='\[\e[38;2;0;0;0m\]'
_FG_OK='\[\e[38;2;165;240;228m\]'
_FG_ERR='\[\e[38;2;255;85;85m\]'

_RESET='\[\e[0m\]'

# Nerd Font icons (UTF-8 encoded for bash 3.2 compatibility)
_SEP_RIGHT=$'\xEE\x82\xB0'    # U+E0B0
_ICON_CLOCK=$'\xEF\x80\x97'       # U+F017
_ICON_FOLDER=$'\xF3\xB0\x89\x96'  # U+F0256 󰉖
_ICON_VENV=$'\xEF\x91\x90'        # from zsh theme
_ICON_BRANCH=$'\xEE\x9C\xA5'      # from zsh theme

_omb_theme_PROMPT_COMMAND() {
  local last_status=$?
  local PR=""

  # Time segment (blue bg)
  PR+="${_BG_FIRST}${_FG_BLACK} ${_ICON_CLOCK} \\t "

  # Venv segment
  if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    local venv_name
    venv_name=$(basename "$VIRTUAL_ENV")
    PR+="${_BG_BLACK}${_FG_FIRST}${_SEP_RIGHT}${_BG_SECOND}${_FG_BLACK}${_SEP_RIGHT}"
    PR+="${_FG_BLACK} ${_ICON_VENV} ${venv_name} "
    local sep_fg="${_FG_SECOND}"
  else
    local sep_fg="${_FG_FIRST}"
  fi

  # Dir + Git
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)

  if [[ -n "$branch" ]]; then
    local dirty=""
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      dirty=" ●"
    fi
    PR+="${_BG_BLACK}${sep_fg}${_SEP_RIGHT}${_BG_THIRD}${_FG_BLACK}${_SEP_RIGHT}"
    PR+="${_FG_BLACK} ${_ICON_FOLDER} \\W "
    PR+="${_BG_BLACK}${_FG_THIRD}${_SEP_RIGHT}${_BG_FOURTH}${_FG_BLACK}${_SEP_RIGHT}"
    PR+="${_FG_BLACK} ${_ICON_BRANCH} ${branch}${dirty} "
    PR+="${_RESET}${_FG_FOURTH}${_SEP_RIGHT}${_RESET}"
  else
    PR+="${_BG_BLACK}${sep_fg}${_SEP_RIGHT}${_BG_FOURTH}${_FG_BLACK}${_SEP_RIGHT}"
    PR+="${_FG_BLACK} ${_ICON_FOLDER} \\W "
    PR+="${_RESET}${_FG_FOURTH}${_SEP_RIGHT}${_RESET}"
  fi

  # Status icon
  if [[ $last_status -eq 0 ]]; then
    PR+=" ${_FG_OK}✓${_RESET} "
  else
    PR+=" ${_FG_ERR}✗${_RESET} "
  fi

  PS1="$PR"
}

_omb_util_add_prompt_command _omb_theme_PROMPT_COMMAND
