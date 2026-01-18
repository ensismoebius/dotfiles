# trap 'read -p ">> $BASH_COMMAND"' DEBUG

# vim:ft=zsh ts=2 sw=2 sts=2
#
# agnoster's Theme - https://gist.github.com/3712874
# A Powerline-inspired theme for ZSH
#
# # README
#
# In order for this theme to render correctly, you will need a
# [Powerline-patched font](https://github.com/Lokaltog/powerline-fonts).
# Make sure you have a recent version: the code points that Powerline
# uses changed in 2012, and older versions will display incorrectly,
# in confusing ways.
#
# In addition, I recommend the
# [Solarized theme](https://github.com/altercation/solarized/) and, if you're
# using it on Mac OS X, [iTerm 2](https://iterm2.com/) over Terminal.app -
# it has significantly better color fidelity.
#
# If using with "light" variant of the Solarized color schema, set
# SOLARIZED_THEME variable to "light". If you don't specify, we'll assume
# you're using the "dark" variant.
#
# # Goals
#
# The aim of this theme is to only show you *relevant* information. Like most
# prompts, it will only show git information when in a git working directory.
# However, it goes a step further: everything from the current user and
# hostname to whether the last call exited with an error to whether background
# jobs are running in this shell will all be displayed automatically when
# appropriate.

### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts

CURRENT_BG='NONE'

case ${SOLARIZED_THEME:-dark} in
    light)
      CURRENT_FG=${CURRENT_FG:-'white'}
      CURRENT_DEFAULT_FG=${CURRENT_DEFAULT_FG:-'white'}
      ;;
    *)
      CURRENT_FG=${CURRENT_FG:-'black'}
      CURRENT_DEFAULT_FG=${CURRENT_DEFAULT_FG:-'default'}
      ;;
esac

### Theme Configuration Initialization
#
# Override these settings in your ~/.zshrc

# Current working directory
: ${AGNOSTER_DIR_FG:=${CURRENT_FG}}
: ${AGNOSTER_DIR_BG:=blue}

# user@host
: ${AGNOSTER_CONTEXT_FG:=${CURRENT_DEFAULT_FG}}
: ${AGNOSTER_CONTEXT_BG:=black}

# Git related
: ${AGNOSTER_GIT_CLEAN_FG:=${CURRENT_FG}}
: ${AGNOSTER_GIT_CLEAN_BG:=green}
: ${AGNOSTER_GIT_DIRTY_FG:=black}
: ${AGNOSTER_GIT_DIRTY_BG:=yellow}

# Bazaar related
: ${AGNOSTER_BZR_CLEAN_FG:=${CURRENT_FG}}
: ${AGNOSTER_BZR_CLEAN_BG:=green}
: ${AGNOSTER_BZR_DIRTY_FG:=black}
: ${AGNOSTER_BZR_DIRTY_BG:=yellow}

# Mercurial related
: ${AGNOSTER_HG_NEWFILE_FG:=white}
: ${AGNOSTER_HG_NEWFILE_BG:=red}
: ${AGNOSTER_HG_CHANGED_FG:=black}
: ${AGNOSTER_HG_CHANGED_BG:=yellow}
: ${AGNOSTER_HG_CLEAN_FG:=${CURRENT_FG}}
: ${AGNOSTER_HG_CLEAN_BG:=green}

# VirtualEnv colors
: ${AGNOSTER_VENV_FG:=black}
: ${AGNOSTER_VENV_BG:=blue}

# AWS Profile colors
: ${AGNOSTER_AWS_PROD_FG:=yellow}
: ${AGNOSTER_AWS_PROD_BG:=red}
: ${AGNOSTER_AWS_FG:=black}
: ${AGNOSTER_AWS_BG:=green}

# Status symbols
: ${AGNOSTER_STATUS_RETVAL_FG:=red}
: ${AGNOSTER_STATUS_ROOT_FG:=yellow}
: ${AGNOSTER_STATUS_JOB_FG:=cyan}
: ${AGNOSTER_STATUS_FG:=${CURRENT_DEFAULT_FG}}
: ${AGNOSTER_STATUS_BG:=black}

## Non-Color settings - set to 'true' to enable
# Show the actual numeric return value rather than a cross symbol.
: ${AGNOSTER_STATUS_RETVAL_NUMERIC:=false}
# Show git working dir in the style "/git/root   master  relative/dir" instead of "/git/root/relative/dir   master"
: ${AGNOSTER_GIT_INLINE:=false}
# Show the git branch status in the prompt rather than the generic branch symbol
: ${AGNOSTER_GIT_BRANCH_STATUS:=true}


# Special Powerline characters

() {
  local LC_ALL="" LC_CTYPE="en_US.UTF-8"
  # NOTE: This segment separator character is correct.  In 2012, Powerline changed
  # the code points they use for their special characters. This is the new code point.
  # If this is not working for you, you probably have an old version of the
  # Powerline-patched fonts installed. Download and install the new version.
  # Do not submit PRs to change this unless you have reviewed the Powerline code point
  # history and have new information.
  # This is defined using a Unicode escape sequence so it is unambiguously readable, regardless of
  # what font the user is viewing this source code in. Do not replace the
  # escape sequence with a single literal character.
  # Do not change this! Do not make it '\u2b80'; that is the old, wrong code point.
  SEGMENT_SEPARATOR=$'\ue0b0'
}

##  Function to adjust the length of a given path string to fit 
##  within a target length. If the path exceeds the target length, 
##  it trims characters from the middle and replaces them with an 
##  ellipsis ("...").
##  Usage: adjust_prompt_len <path> <target_length>
adjust_prompt_len() {
  local pstr=$1
  local target=$2

  # Remove prompt escapes for accurate length
  local clean_path=$(echo "$pstr" | sed 's/%{[^}]*%}//g')
  local len=${#clean_path}

  # Too short → unchanged
  (( len <= target )) && {
    printf '%s\n' "$clean_path"
    return
  }

  # Not enough room for ellipsis
  (( target < 5 )) && {
    printf '%s\n' "${clean_path:len-target}"
    return
  }

  local ellipsis="..."
  local keep=$(( target - ${#ellipsis} ))

  local left=$(( keep / 2 ))
  local right=$(( keep - left ))

  printf '%s%s%s\n' \
    "${clean_path:0:$left}" \
    "$ellipsis" \
    "${clean_path:$(($len-$right)):$right}"
}


# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi

  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

git_toplevel() {
	local repo_root=$(git rev-parse --show-toplevel)
	if [[ $repo_root = '' ]]; then
		# We are in a bare repo. Use git dir as root
		repo_root=$(git rev-parse --git-dir)
		if [[ $repo_root = '.' ]]; then
			repo_root=$PWD
		fi
	fi
	echo -n $repo_root
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

prompt_context() {
  if [[ "$USERNAME" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    if [[ -n "$SSH_CLIENT" ]]; then
      # Over SSH: show user@host
      prompt_segment "$AGNOSTER_CONTEXT_BG" "$AGNOSTER_CONTEXT_FG" "%(!.%{%F{$AGNOSTER_STATUS_ROOT_FG}%}.)%n@%m"
    else
      # Local: show only user
      prompt_segment "$AGNOSTER_CONTEXT_BG" "$AGNOSTER_CONTEXT_FG" "%(!.%{%F{$AGNOSTER_STATUS_ROOT_FG}%}.)%n"
    fi
  fi
}


prompt_git_relative() {
  local repo_root=$(git_toplevel)
  local path_in_repo=$(pwd | sed "s/^$(echo "$repo_root" | sed 's:/:\\/:g;s/\$/\\$/g')//;s:^/::;s:/$::;")
  if [[ $path_in_repo != '' ]]; then
    prompt_segment "$AGNOSTER_DIR_BG" "$AGNOSTER_DIR_FG" "$path_in_repo"
  fi;
}

# Git: branch/detached head, dirty status
prompt_git() {
  (( $+commands[git] )) || return
  if [[ "$(command git config --get oh-my-zsh.hide-status 2>/dev/null)" = 1 ]]; then
    return
  fi
  local PL_BRANCH_CHAR
  () {
    local LC_ALL="" LC_CTYPE="en_US.UTF-8"
    PL_BRANCH_CHAR=$'\ue0a0'         # 
  }
  local ref dirty mode repo_path

   if [[ "$(command git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]]; then
    repo_path=$(command git rev-parse --git-dir 2>/dev/null)
    dirty=$(parse_git_dirty)
    ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
    ref="◈ $(command git describe --exact-match --tags HEAD 2> /dev/null)" || \
    ref="➦ $(command git rev-parse --short HEAD 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment "$AGNOSTER_GIT_DIRTY_BG" "$AGNOSTER_GIT_DIRTY_FG"
    else
      prompt_segment "$AGNOSTER_GIT_CLEAN_BG" "$AGNOSTER_GIT_CLEAN_FG"
    fi

    if [[ $AGNOSTER_GIT_BRANCH_STATUS == 'true' ]]; then
      local ahead behind
      ahead=$(command git log --oneline @{upstream}.. 2>/dev/null)
      behind=$(command git log --oneline ..@{upstream} 2>/dev/null)
      if [[ -n "$ahead" ]] && [[ -n "$behind" ]]; then
        PL_BRANCH_CHAR=$'\u21c5'
      elif [[ -n "$ahead" ]]; then
        PL_BRANCH_CHAR=$'\u21b1'
      elif [[ -n "$behind" ]]; then
        PL_BRANCH_CHAR=$'\u21b0'
      fi
    fi

    if [[ -e "${repo_path}/BISECT_LOG" ]]; then
      mode=" <B>"
    elif [[ -e "${repo_path}/MERGE_HEAD" ]]; then
      mode=" >M<"
    elif [[ -e "${repo_path}/rebase" || -e "${repo_path}/rebase-apply" || -e "${repo_path}/rebase-merge" || -e "${repo_path}/../.dotest" ]]; then
      mode=" >R>"
    fi

    setopt promptsubst
    autoload -Uz vcs_info

    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:*' get-revision true
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '✚'
    zstyle ':vcs_info:*' unstagedstr '±'
    zstyle ':vcs_info:*' formats ' %u%c'
    zstyle ':vcs_info:*' actionformats ' %u%c'
    vcs_info
    echo -n "${${ref:gs/%/%%}/refs\/heads\//$PL_BRANCH_CHAR }${vcs_info_msg_0_%% }${mode}"
    [[ $AGNOSTER_GIT_INLINE == 'true' ]] && prompt_git_relative
  fi
}

# Dir: current working directory
prompt_dir() {
  local dir_path
  if [[ $AGNOSTER_GIT_INLINE == 'true' ]] && $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    # Git repo and inline path enabled, hence only show the git root
    dir_path="$(git_toplevel | sed "s:^$HOME:~:")"
  else
    dir_path=$(print -P %~)
  fi
  # Shorten the directory path for the prompt
  local short_dir_path=$(adjust_prompt_len "$dir_path" "$COLUMNS")
  prompt_segment "$AGNOSTER_DIR_BG" "$AGNOSTER_DIR_FG" "$short_dir_path"
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  if [ -n "$CONDA_DEFAULT_ENV" ]; then
    prompt_segment magenta $CURRENT_FG "🐍 $CONDA_DEFAULT_ENV"
  fi
  if [[ -n "$VIRTUAL_ENV" && -n "$VIRTUAL_ENV_DISABLE_PROMPT" ]]; then
    prompt_segment "$AGNOSTER_VENV_BG" "$AGNOSTER_VENV_FG" "(${VIRTUAL_ENV:t:gs/%/%%})"
  fi
}

# Status:
# - was there an error
# - am I root
# - are there background jobs?
prompt_status() {
  local -a symbols

  if [[ $AGNOSTER_STATUS_RETVAL_NUMERIC == 'true' ]]; then
    [[ $RETVAL -ne 0 ]] && symbols+="%{%F{$AGNOSTER_STATUS_RETVAL_FG}%}$RETVAL"
  else
    [[ $RETVAL -ne 0 ]] && symbols+="%{%F{$AGNOSTER_STATUS_RETVAL_FG}%}✘"
  fi
  [[ $UID -eq 0 ]] && symbols+="%{%F{$AGNOSTER_STATUS_ROOT_FG}%}⚡"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{$AGNOSTER_STATUS_JOB_FG}%}⚙"

  [[ -n "$symbols" ]] && prompt_segment "$AGNOSTER_STATUS_BG" "$AGNOSTER_STATUS_FG" "$symbols"
}

build_prompt_full() {
  prompt_status
	prompt_virtualenv
  prompt_context
	prompt_dir
	prompt_git
	prompt_end
}

build_prompt_compact() {
  prompt_status
	prompt_dir
	prompt_git
	prompt_end
}

## Main prompt
build_prompt() {
  RETVAL=$?
  CURRENT_BG='NONE'

  # Update COLUMNS dynamically to handle terminal resizing
  (( COLUMNS = $(tput cols) - 10 )) # Add a buffer to make the prompt slightly shorter

  # Determine the real directory string (expand %~)
  local dir_path
  if [[ $AGNOSTER_GIT_INLINE == 'true' ]] && $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dir_path="$(git_toplevel | sed "s:^$HOME:~:")"
  else
    dir_path=$(print -P %~)
  fi

  # Capture the other segments in subshells to measure visible width
  local prefix_full suffix_full
  prefix_full=$( (prompt_status; prompt_virtualenv; prompt_context) 2>/dev/null )
  suffix_full=$( (prompt_git; prompt_end) 2>/dev/null )

  # Strip escape sequences from prefix and suffix
  local clean_prefix clean_suffix
  clean_prefix=${(S)${(Q)${(b)${(%)prefix_full}}}}
  clean_suffix=${(S)${(Q)${(b)${(%)suffix_full}}}}

  # Measure visible width (expand prompt escapes then count)
  local full_prompt rendered_full visible_full
  full_prompt="${clean_prefix}${dir_path}${clean_suffix}"
  rendered_full=${(%)full_prompt}

  # Strip ANSI escape sequences from rendered_full
  local clean_rendered_full
  clean_rendered_full=$(echo "$rendered_full" | sed 's/\x1b\[[0-9;]*m//g')
  visible_full=${#${(S)${(Q)${(b)clean_rendered_full}}}}

  # If it fits, render the full prompt normally (no shortening)
  if (( visible_full <= COLUMNS )); then
    CURRENT_BG='NONE'
    prompt_status
    prompt_virtualenv
    prompt_context
    prompt_segment "$AGNOSTER_DIR_BG" "$AGNOSTER_DIR_FG" "$dir_path"
    prompt_git
    prompt_end
    return
  fi

  # Otherwise shorten only the directory enough to fit
  local excess target_len short_dir
  excess=$(( visible_full - COLUMNS ))
  target_len=$(( ${#dir_path} - excess ))
  # leave a small minimum to keep readability
  (( target_len < 5 )) && target_len=5

  short_dir=$(adjust_prompt_len "$dir_path" "$target_len")

  # Render with shortened directory
  CURRENT_BG='NONE'
  prompt_status
  prompt_virtualenv
  prompt_context
  prompt_segment "$AGNOSTER_DIR_BG" "$AGNOSTER_DIR_FG" "$short_dir"
  prompt_git
  prompt_end
}

PROMPT='%{%f%b%k%}$(build_prompt) 
'

