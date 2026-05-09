# Catppuccin Mocha prompt (zsh)
# Isolated rcfile for the Command plugin terminal — your ~/.zshrc is not sourced.
# Source of truth: src/prompts/zsh.zsh in the plugin repo.

setopt PROMPT_SUBST
zmodload zsh/datetime 2>/dev/null || true

__cm_rosewater='#f5e0dc'
__cm_mauve='#cba6f7'
__cm_blue='#89b4fa'
__cm_green='#a6e3a1'
__cm_peach='#fab387'
__cm_yellow='#f9e2af'
__cm_red='#f38ba8'
__cm_base='#1e1e2e'
__cm_surface0='#313244'
__cm_subtext='#a6adc8'
__cm_overlay0='#6c7086'

__cm_prompt_file=${(%):-%x}
[[ -z "$__cm_prompt_file" ]] && __cm_prompt_file=$0
__cm_runtime_root=${${__cm_prompt_file:A}:h:h}
__cm_config_path=${COMMAND_PROMPT_CONFIG:-${__cm_runtime_root:+$__cm_runtime_root/prompt.conf}}
__cm_config_path=${__cm_config_path:-"$HOME/.config/obsidian-command/prompt.conf"}
__cm_wizard_path=${COMMAND_PROMPT_WIZARD:-${__cm_runtime_root:+$__cm_runtime_root/prmptwiz.sh}}
__cm_wizard_path=${__cm_wizard_path:-"${__cm_config_path:h}/prmptwiz.sh"}

__cm_prompt_style=lean
__cm_config_version=0
__cm_prompt_layout=two_line
__cm_prompt_spacing=sparse
__cm_charset=nerd
__cm_show_os=yes
__cm_show_user=yes
__cm_show_host=yes
__cm_show_git=yes
__cm_git_detail=status
__cm_show_status=no
__cm_show_duration=no
__cm_duration_threshold=2
__cm_show_time=yes
__cm_time_format=24h
__cm_right_prompt=yes
__cm_prompt_char='❯'
__cm_accent=mauve
__cm_dir_style=full

__cm_reset='%f%b%k'
__cm_arrow=$''
__cm_branch=$''
__cm_frame_top=$'╭─'
__cm_frame_bottom=$'╰─'
__cm_fail_mark=$'✘'
__cm_ahead=$'⇡'
__cm_behind=$'⇣'
__cm_prompt_color=$__cm_mauve
__cm_cmd_start=${EPOCHSECONDS:-$SECONDS}
__cm_last_duration=0
__cm_prompt_head=
__cm_os_id=
__cm_os_like=
__cm_os_loaded=0

__cm_load_config() {
  __cm_prompt_style=lean
  __cm_config_version=0
  __cm_prompt_layout=two_line
  __cm_prompt_spacing=sparse
  __cm_charset=nerd
  __cm_show_os=yes
  __cm_show_user=yes
  __cm_show_host=yes
  __cm_show_git=yes
  __cm_git_detail=status
  __cm_show_status=no
  __cm_show_duration=no
  __cm_duration_threshold=2
  __cm_show_time=yes
  __cm_time_format=24h
  __cm_right_prompt=yes
  __cm_prompt_char='❯'
  __cm_accent=mauve
  __cm_dir_style=full

  if [[ -f "$__cm_config_path" ]]; then
    local key value
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
      case "$key" in
        COMMAND_PROMPT_VERSION) __cm_config_version=$value ;;
        COMMAND_PROMPT_STYLE) __cm_prompt_style=$value ;;
        COMMAND_PROMPT_LAYOUT) __cm_prompt_layout=$value ;;
        COMMAND_PROMPT_SPACING) __cm_prompt_spacing=$value ;;
        COMMAND_PROMPT_CHARSET) __cm_charset=$value ;;
        COMMAND_PROMPT_SHOW_OS) __cm_show_os=$value ;;
        COMMAND_PROMPT_SHOW_USER) __cm_show_user=$value ;;
        COMMAND_PROMPT_SHOW_HOST) __cm_show_host=$value ;;
        COMMAND_PROMPT_SHOW_GIT) __cm_show_git=$value ;;
        COMMAND_PROMPT_GIT_DETAIL) __cm_git_detail=$value ;;
        COMMAND_PROMPT_SHOW_STATUS) __cm_show_status=$value ;;
        COMMAND_PROMPT_SHOW_DURATION) __cm_show_duration=$value ;;
        COMMAND_PROMPT_DURATION_THRESHOLD) __cm_duration_threshold=$value ;;
        COMMAND_PROMPT_SHOW_TIME) __cm_show_time=$value ;;
        COMMAND_PROMPT_TIME_FORMAT) __cm_time_format=$value ;;
        COMMAND_PROMPT_RIGHT_PROMPT) __cm_right_prompt=$value ;;
        COMMAND_PROMPT_PROMPT_CHAR) __cm_prompt_char=${value:-❯} ;;
        COMMAND_PROMPT_ACCENT) __cm_accent=$value ;;
        COMMAND_PROMPT_DIR_STYLE) __cm_dir_style=$value ;;
      esac
    done < "$__cm_config_path"
  fi

  [[ "$__cm_prompt_style" == powerline ]] && __cm_prompt_style=rainbow
  case "$__cm_prompt_style" in lean|classic|rainbow|pure|minimal) ;; *) __cm_prompt_style=rainbow ;; esac
  case "$__cm_prompt_layout" in one_line|two_line) ;; *) __cm_prompt_layout=two_line ;; esac
  case "$__cm_prompt_spacing" in compact|sparse) ;; *) __cm_prompt_spacing=sparse ;; esac
  case "$__cm_charset" in nerd|unicode|ascii) ;; *) __cm_charset=nerd ;; esac
  case "$__cm_show_os" in yes|no) ;; *) __cm_show_os=yes ;; esac
  case "$__cm_show_user" in yes|no) ;; *) __cm_show_user=yes ;; esac
  case "$__cm_show_host" in yes|no) ;; *) __cm_show_host=yes ;; esac
  case "$__cm_show_git" in yes|no) ;; *) __cm_show_git=yes ;; esac
  case "$__cm_git_detail" in branch|status) ;; *) __cm_git_detail=status ;; esac
  case "$__cm_show_status" in yes|no) ;; *) __cm_show_status=no ;; esac
  case "$__cm_show_duration" in yes|no) ;; *) __cm_show_duration=no ;; esac
  case "$__cm_duration_threshold" in ''|*[!0-9]*) __cm_duration_threshold=2 ;; esac
  case "$__cm_show_time" in yes|no) ;; *) __cm_show_time=yes ;; esac
  case "$__cm_time_format" in 12h|24h) ;; *) __cm_time_format=24h ;; esac
  case "$__cm_right_prompt" in yes|no) ;; *) __cm_right_prompt=yes ;; esac
  case "$__cm_accent" in mauve|blue|green|peach|rosewater) ;; *) __cm_accent=mauve ;; esac
  case "$__cm_dir_style" in full|short|repo) ;; *) __cm_dir_style=full ;; esac

  case "$__cm_accent" in
    blue) __cm_prompt_color=$__cm_blue ;;
    green) __cm_prompt_color=$__cm_green ;;
    peach) __cm_prompt_color=$__cm_peach ;;
    rosewater) __cm_prompt_color=$__cm_rosewater ;;
    *) __cm_prompt_color=$__cm_mauve ;;
  esac

  case "$__cm_charset" in
    ascii)
      __cm_arrow=
      __cm_branch='git:'
      __cm_frame_top='+-'
      __cm_frame_bottom='+-'
      __cm_fail_mark='x'
      __cm_ahead='^'
      __cm_behind='v'
      [[ "$__cm_prompt_char" == '❯' || "$__cm_prompt_char" == '➜' || "$__cm_prompt_char" == 'λ' ]] && __cm_prompt_char='>'
      ;;
    unicode)
      __cm_arrow=
      __cm_branch='git'
      __cm_frame_top=$'╭─'
      __cm_frame_bottom=$'╰─'
      __cm_fail_mark=$'✘'
      __cm_ahead=$'↑'
      __cm_behind=$'↓'
      ;;
    *)
      __cm_arrow=$''
      __cm_branch=$''
      __cm_frame_top=$'╭─'
      __cm_frame_bottom=$'╰─'
      __cm_fail_mark=$'✘'
      __cm_ahead=$'⇡'
      __cm_behind=$'⇣'
      ;;
  esac
}

__cm_needs_wizard() {
  [[ -f "$__cm_config_path" ]] || return 0
  local key value version=0
  while IFS='=' read -r key value || [[ -n "$key" ]]; do
    if [[ "$key" == COMMAND_PROMPT_VERSION ]]; then
      version=$value
      break
    fi
  done < "$__cm_config_path"
  [[ "$version" != 2 ]]
}

prmptwiz() {
  if [[ -z "$__cm_wizard_path" || ! -f "$__cm_wizard_path" ]]; then
    print -ru2 -- "Prompt wizard is unavailable: ${__cm_wizard_path:-COMMAND_PROMPT_WIZARD} was not found."
    return 1
  fi
  COMMAND_PROMPT_CONFIG="$__cm_config_path" sh "$__cm_wizard_path"
  local code=$?
  __cm_load_config
  return "$code"
}

promptwiz() {
  prmptwiz "$@"
}

__cm_first_run() {
  if __cm_needs_wizard && [[ -t 0 && -t 1 ]]; then
    prmptwiz
  else
    __cm_load_config
  fi
}

__cm_fg() {
  if [[ ${2:-} == bold ]]; then
    print -nr -- "%B%F{$1}"
  else
    print -nr -- "%F{$1}"
  fi
}

__cm_bgfg() {
  print -nr -- "%K{$1}%F{$2}"
}

__cm_separator() {
  local from=$1 to=${2:-}
  if [[ -n "$__cm_arrow" && -n "$to" ]]; then
    print -nr -- "%k%F{$from}%K{$to}${__cm_arrow}%k%f"
  elif [[ -n "$__cm_arrow" ]]; then
    print -nr -- "%k%F{$from}${__cm_arrow}%f"
  else
    print -nr -- "%k%f "
  fi
}

__cm_prompt_escape() {
  local s=${1//$'\n'/ }
  s=${s//\\/\\\\}
  s=${s//\$/\\$}
  s=${s//\`/\\\`}
  s=${s//\%/%%}
  print -nr -- "$s"
}

__cm_read_os_release() {
  (( __cm_os_loaded )) && return
  local release_file key value
  for release_file in /etc/os-release /usr/lib/os-release; do
    [[ -r "$release_file" ]] || continue
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
      value=${value#\"}
      value=${value%\"}
      case "$key" in
        ID) __cm_os_id=$value ;;
        ID_LIKE) __cm_os_like=$value ;;
      esac
    done < "$release_file"
    [[ -n "$__cm_os_id" ]] && break
  done
  __cm_os_id=${__cm_os_id:-linux}
  __cm_os_loaded=1
}

__cm_os_logo() {
  [[ "$__cm_show_os" == yes ]] || return
  __cm_read_os_release
  local os_key="$__cm_os_id $__cm_os_like"
  if [[ "$__cm_charset" == ascii ]]; then
    __cm_prompt_escape "$__cm_os_id"
    return
  fi
  if [[ "$__cm_charset" == unicode ]]; then
    print -nr -- 'linux'
    return
  fi
  case "$os_key" in
    *fedora*|*bazzite*) print -nr -- '' ;;
    *ubuntu*) print -nr -- '' ;;
    *debian*) print -nr -- '' ;;
    *arch*) print -nr -- '' ;;
    *nixos*) print -nr -- '' ;;
    *manjaro*) print -nr -- '' ;;
    *opensuse*|*suse*) print -nr -- '' ;;
    *alpine*) print -nr -- '' ;;
    *centos*) print -nr -- '' ;;
    *gentoo*) print -nr -- '' ;;
    *kali*) print -nr -- '' ;;
    *pop*) print -nr -- '' ;;
    *rocky*) print -nr -- '' ;;
    *) print -nr -- '' ;;
  esac
}

__cm_identity_text() {
  local os identity badge out=""
  os=$(__cm_os_logo)
  if [[ "$__cm_show_host" == yes ]]; then
    [[ "$__cm_show_user" == yes ]] && identity='%n@%m'
  else
    [[ "$__cm_show_user" == yes ]] && identity='%n'
  fi
  if [[ -n "$os" ]]; then
    badge="$(__cm_fg "$__cm_prompt_color" bold)${os}${__cm_reset}"
    out=$badge
    [[ -n "$identity" ]] && out+=" $(__cm_fg "$__cm_prompt_color" bold)${identity}${__cm_reset}"
  elif [[ -n "$identity" ]]; then
    out="$(__cm_fg "$__cm_prompt_color" bold)${identity}${__cm_reset}"
  fi
  print -nr -- "$out"
}

__cm_dir_text() {
  local root rel text
  case "$__cm_dir_style" in
    short)
      print -nr -- '%1~'
      ;;
    repo)
      root=$(git rev-parse --show-toplevel 2>/dev/null) || {
        print -nr -- '%~'
        return
      }
      rel=${PWD#"$root"}
      rel=${rel#/}
      text="${root:t}"
      [[ -n "$rel" ]] && text+="/$rel"
      __cm_prompt_escape "$text"
      ;;
    *)
      print -nr -- '%~'
      ;;
  esac
}

__cm_git_branch_name() {
  git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

__cm_git_info() {
  [[ "$__cm_show_git" == yes ]] || return
  local branch git_output line x y text color dirty
  local staged=0 changed=0 untracked=0 conflicted=0 ahead=0 behind=0
  branch=$(__cm_git_branch_name) || return
  [[ -n "$branch" ]] || return

  if [[ "$__cm_git_detail" == branch ]]; then
    print -nr -- "$(__cm_prompt_escape "$branch")"$'\t'"$__cm_green"
    return
  fi

  git_output=$(git status --porcelain=v1 --branch --ignore-submodules=dirty 2>/dev/null) || return
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    if [[ "$line" == '## '* ]]; then
      [[ "$line" =~ 'ahead[[:space:]]+([0-9]+)' ]] && ahead=$match[1]
      [[ "$line" =~ 'behind[[:space:]]+([0-9]+)' ]] && behind=$match[1]
      continue
    fi
    if [[ "$line" == '??'* ]]; then
      (( untracked++ ))
      continue
    fi
    case "${line[1,2]}" in
      DD|AU|UD|UA|DU|AA|UU) (( conflicted++ )) ;;
    esac
    x=${line[1]}
    y=${line[2]}
    [[ "$x" != ' ' && "$x" != '?' ]] && (( staged++ ))
    [[ "$y" != ' ' && "$y" != '?' ]] && (( changed++ ))
  done <<< "$git_output"

  text=$(__cm_prompt_escape "$branch")
  (( ahead > 0 )) && text+=" ${__cm_ahead}${ahead}"
  (( behind > 0 )) && text+=" ${__cm_behind}${behind}"
  (( staged > 0 )) && text+=" +${staged}"
  (( changed > 0 )) && text+=" ~${changed}"
  (( untracked > 0 )) && text+=" ?${untracked}"
  (( conflicted > 0 )) && text+=" !${conflicted}"
  dirty=$((ahead + behind + staged + changed + untracked + conflicted))
  if (( conflicted > 0 )); then
    color=$__cm_red
  elif (( dirty > 0 )); then
    color=$__cm_yellow
  else
    color=$__cm_green
  fi
  print -nr -- "$text"$'\t'"$color"
}

__cm_split_git_info() {
  local info
  info=$(__cm_git_info)
  [[ -n "$info" ]] || return 1
  __cm_git_text=${info%$'\t'*}
  __cm_git_color=${info##*$'\t'}
}

__cm_format_duration() {
  local seconds=$1 minutes rest
  if (( seconds >= 60 )); then
    minutes=$((seconds / 60))
    rest=$((seconds % 60))
    print -nr -- "${minutes}m${(l:2::0:)rest}s"
  else
    print -nr -- "${seconds}s"
  fi
}

__cm_runtime_text() {
  local -a parts
  local duration time_value
  parts=()
  if [[ "$__cm_show_duration" == yes ]] && (( __cm_last_duration >= __cm_duration_threshold )); then
    duration=$(__cm_format_duration "$__cm_last_duration")
    parts+=("took $duration")
  fi
  if [[ "$__cm_show_time" == yes ]]; then
    if [[ "$__cm_time_format" == 12h ]]; then
      time_value=$(date '+%I:%M %p' 2>/dev/null)
    else
      time_value=$(date '+%H:%M' 2>/dev/null)
    fi
    [[ -n "$time_value" ]] && parts+=("$time_value")
  fi
  (( ${#parts[@]} )) || return 1
  __cm_prompt_escape "${(j:  :)parts}"
}

__cm_plain_modules() {
  local id dir git runtime ps=""
  id=$(__cm_identity_text)
  dir=$(__cm_dir_text)
  [[ -n "$id" ]] && ps+="${id} "
  ps+="$(__cm_fg "$__cm_peach" bold)${dir}${__cm_reset}"
  if __cm_split_git_info; then
    git="${__cm_branch} ${__cm_git_text}"
    ps+=" $(__cm_fg "$__cm_git_color" bold)${git}${__cm_reset}"
  fi
  if [[ "$__cm_right_prompt" != yes ]]; then
    runtime=$(__cm_runtime_text) && ps+=" $(__cm_fg "$__cm_subtext")${runtime}${__cm_reset}"
  fi
  print -nr -- "$ps"
}

__cm_rainbow_head() {
  local id dir runtime ps current_bg
  id=$(__cm_identity_text)
  dir=$(__cm_dir_text)
  if [[ -n "$id" ]]; then
    ps="$(__cm_bgfg "$__cm_prompt_color" "$__cm_base") ${id} "
    ps+="$(__cm_separator "$__cm_prompt_color" "$__cm_peach")"
    ps+="$(__cm_bgfg "$__cm_peach" "$__cm_base") ${dir} "
    current_bg=$__cm_peach
  else
    ps="$(__cm_bgfg "$__cm_peach" "$__cm_base") ${dir} "
    current_bg=$__cm_peach
  fi

  if __cm_split_git_info; then
    ps+="$(__cm_separator "$current_bg" "$__cm_git_color")"
    ps+="$(__cm_bgfg "$__cm_git_color" "$__cm_base") ${__cm_branch} ${__cm_git_text} "
    current_bg=$__cm_git_color
  fi

  if [[ "$__cm_right_prompt" != yes ]]; then
    runtime=$(__cm_runtime_text) && {
      ps+="$(__cm_separator "$current_bg" "$__cm_surface0")"
      ps+="$(__cm_bgfg "$__cm_surface0" "$__cm_subtext") ${runtime} "
      current_bg=$__cm_surface0
    }
  fi

  ps+="$(__cm_separator "$current_bg")"
  __cm_prompt_head=$ps
}

__cm_visible_length() {
  local s=${(%)1}
  s=${(S)s//$'\e'\[[0-9\;]##m/}
  print -nr -- ${#s}
}

__cm_with_right_fill() {
  local left=$1 right=$2 cols left_w right_w pad fill
  cols=${COLUMNS:-80}
  if [[ -z "$right" ]]; then
    print -nr -- "$left"
    return
  fi
  left_w=$(__cm_visible_length "$left")
  right_w=$(__cm_visible_length "$right")
  pad=$(( cols - left_w - right_w - 2 ))
  if (( pad > 2 )); then
    if [[ "$__cm_charset" == ascii ]]; then
      fill="${(l:pad::-:)}"
    else
      fill="${(l:pad::─:)}"
    fi
    print -nr -- "${left} $(__cm_fg "$__cm_overlay0")${fill}${__cm_reset} ${right}"
  else
    print -nr -- "${left}  ${right}"
  fi
}

__cm_lean_head() {
  local modules left right rt
  modules=$(__cm_plain_modules)
  if [[ "$__cm_prompt_layout" == two_line ]]; then
    left="$(__cm_fg "$__cm_prompt_color" bold)${__cm_frame_top}${__cm_reset} ${modules}"
  else
    left=$modules
  fi
  if [[ "$__cm_right_prompt" == yes ]] && rt=$(__cm_runtime_text); then
    right="$(__cm_fg "$__cm_subtext")${rt}${__cm_reset}"
  fi
  __cm_prompt_head=$(__cm_with_right_fill "$left" "$right")
}

__cm_classic_head() {
  __cm_prompt_head=$(__cm_plain_modules)
}

__cm_pure_head() {
  local dir git runtime ps
  dir=$(__cm_dir_text)
  ps="$(__cm_fg "$__cm_blue" bold)${dir}${__cm_reset}"
  if __cm_split_git_info; then
    git="${__cm_branch} ${__cm_git_text}"
    ps+=" $(__cm_fg "$__cm_git_color")${git}${__cm_reset}"
  fi
  if [[ "$__cm_right_prompt" != yes ]]; then
    runtime=$(__cm_runtime_text) && ps+=" $(__cm_fg "$__cm_subtext")${runtime}${__cm_reset}"
  fi
  __cm_prompt_head=$ps
}

__cm_minimal_head() {
  local dir git ps
  dir=$(__cm_dir_text)
  ps="$(__cm_fg "$__cm_peach")${dir}${__cm_reset}"
  if __cm_split_git_info; then
    git=$__cm_git_text
    ps+=" $(__cm_fg "$__cm_git_color")${git}${__cm_reset}"
  fi
  __cm_prompt_head=$ps
}

__cm_set_right_prompt() {
  local runtime
  RPROMPT=
  [[ "$__cm_right_prompt" == yes ]] || return
  [[ "$__cm_prompt_style" == lean ]] && return
  runtime=$(__cm_runtime_text) || return
  RPROMPT="$(__cm_fg "$__cm_subtext")${runtime}${__cm_reset}"
}

__cm_set_prompt() {
  local last=$1 now prompt_col prompt_mark status_text bottom
  now=${EPOCHSECONDS:-$SECONDS}
  __cm_last_duration=$((now - __cm_cmd_start))
  __cm_load_config

  if (( last == 0 )); then
    prompt_col=$__cm_prompt_color
  else
    prompt_col=$__cm_red
    [[ "$__cm_show_status" == yes ]] && status_text=" ${__cm_fail_mark} ${last}"
  fi
  prompt_mark="$(__cm_fg "$prompt_col" bold)$(__cm_prompt_escape "$__cm_prompt_char")${status_text}${__cm_reset} "

  case "$__cm_prompt_style" in
    lean) __cm_lean_head ;;
    classic) __cm_classic_head ;;
    pure) __cm_pure_head ;;
    minimal) __cm_minimal_head ;;
    *) __cm_rainbow_head ;;
  esac

  if [[ "$__cm_prompt_style" == lean && "$__cm_prompt_layout" == two_line ]]; then
    bottom="$(__cm_fg "$__cm_prompt_color" bold)${__cm_frame_bottom}${__cm_reset} ${prompt_mark}"
    PROMPT="${__cm_prompt_head}
${bottom}"
  elif [[ "$__cm_prompt_layout" == one_line && "$__cm_prompt_style" != pure ]]; then
    PROMPT="${__cm_prompt_head} ${prompt_mark}"
  else
    PROMPT="${__cm_prompt_head}
${prompt_mark}"
  fi

  [[ "$__cm_prompt_spacing" == sparse ]] && PROMPT="
${PROMPT}"
  __cm_set_right_prompt
}

preexec() {
  __cm_cmd_start=${EPOCHSECONDS:-$SECONDS}
}

precmd() {
  local last=$?
  __cm_set_prompt "$last"
}

__cm_first_run
