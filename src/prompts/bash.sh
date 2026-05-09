# Catppuccin Mocha prompt (bash)
# Isolated rcfile for the Command plugin terminal — your ~/.bashrc is not sourced.
# Source of truth: src/prompts/bash.sh in the plugin repo.

__cm_rosewater='245;224;220'
__cm_mauve='203;166;247'
__cm_blue='137;180;250'
__cm_green='166;227;161'
__cm_peach='250;179;135'
__cm_yellow='249;226;175'
__cm_red='243;139;168'
__cm_base='30;30;46'
__cm_surface0='49;50;68'
__cm_subtext='166;173;200'
__cm_overlay0='108;112;134'

__cm_runtime_root=
__cm_prompt_file=${BASH_SOURCE[0]:-${0}}
if [[ -n "$__cm_prompt_file" ]]; then
  __cm_runtime_root=$(cd -- "$(dirname -- "$__cm_prompt_file")/.." 2>/dev/null && pwd -P)
fi
__cm_config_path=${COMMAND_PROMPT_CONFIG:-${__cm_runtime_root:+$__cm_runtime_root/prompt.conf}}
__cm_config_path=${__cm_config_path:-"$HOME/.config/obsidian-command/prompt.conf"}
__cm_wizard_path=${COMMAND_PROMPT_WIZARD:-${__cm_runtime_root:+$__cm_runtime_root/prmptwiz.sh}}
__cm_wizard_path=${__cm_wizard_path:-"$(dirname -- "$__cm_config_path")/prmptwiz.sh"}

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

__cm_reset='\[\e[0m\]'
__cm_arrow=$''
__cm_branch=$''
__cm_frame_top=$'╭─'
__cm_frame_bottom=$'╰─'
__cm_fail_mark=$'✘'
__cm_ahead=$'⇡'
__cm_behind=$'⇣'
__cm_prompt_color=$__cm_mauve
__cm_cmd_start=${SECONDS:-0}
__cm_last_duration=0
__cm_in_prompt=0
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
    [[ "$key" == COMMAND_PROMPT_VERSION ]] && {
      version=$value
      break
    }
  done < "$__cm_config_path"
  [[ "$version" != 2 ]]
}

prmptwiz() {
  if [[ -z "$__cm_wizard_path" || ! -f "$__cm_wizard_path" ]]; then
    printf 'Prompt wizard is unavailable: %s was not found.\n' "${__cm_wizard_path:-COMMAND_PROMPT_WIZARD}" >&2
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
    printf '\[\e[1;38;2;%sm\]' "$1"
  else
    printf '\[\e[38;2;%sm\]' "$1"
  fi
}

__cm_bgfg() {
  printf '\[\e[48;2;%s;38;2;%sm\]' "$1" "$2"
}

__cm_separator() {
  local from=$1 to=${2:-}
  if [[ -n "$__cm_arrow" && -n "$to" ]]; then
    printf '\[\e[0;38;2;%s;48;2;%sm\]%s' "$from" "$to" "$__cm_arrow"
  elif [[ -n "$__cm_arrow" ]]; then
    printf '\[\e[0;38;2;%sm\]%s%s' "$from" "$__cm_arrow" "$__cm_reset"
  else
    printf '%s ' "$__cm_reset"
  fi
}

__cm_prompt_escape() {
  local s=${1//$'\n'/ }
  s=${s//\\/\\\\}
  s=${s//\$/\\$}
  s=${s//\`/\\\`}
  s=${s//!/\\!}
  printf '%s' "$s"
}

__cm_read_os_release() {
  (( __cm_os_loaded )) && return
  local file key value
  for file in /etc/os-release /usr/lib/os-release; do
    [[ -r "$file" ]] || continue
    while IFS='=' read -r key value || [[ -n "$key" ]]; do
      value=${value#\"}
      value=${value%\"}
      case "$key" in
        ID) __cm_os_id=$value ;;
        ID_LIKE) __cm_os_like=$value ;;
      esac
    done < "$file"
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
    printf 'linux'
    return
  fi
  case "$os_key" in
    *fedora*|*bazzite*) printf '' ;;
    *ubuntu*) printf '' ;;
    *debian*) printf '' ;;
    *arch*) printf '' ;;
    *nixos*) printf '' ;;
    *manjaro*) printf '' ;;
    *opensuse*|*suse*) printf '' ;;
    *alpine*) printf '' ;;
    *centos*) printf '' ;;
    *gentoo*) printf '' ;;
    *kali*) printf '' ;;
    *pop*) printf '' ;;
    *rocky*) printf '' ;;
    *) printf '' ;;
  esac
}

__cm_identity_text() {
  local os identity badge out=""
  os=$(__cm_os_logo)
  if [[ "$__cm_show_host" == yes ]]; then
    [[ "$__cm_show_user" == yes ]] && identity='\u@\h'
  else
    [[ "$__cm_show_user" == yes ]] && identity='\u'
  fi
  if [[ -n "$os" ]]; then
    badge="$(__cm_fg "$__cm_prompt_color" bold)${os}${__cm_reset}"
    out=$badge
    [[ -n "$identity" ]] && out+=" $(__cm_fg "$__cm_prompt_color" bold)${identity}${__cm_reset}"
  elif [[ -n "$identity" ]]; then
    out="$(__cm_fg "$__cm_prompt_color" bold)${identity}${__cm_reset}"
  fi
  printf '%s' "$out"
}

__cm_dir_text() {
  local root rel text
  case "$__cm_dir_style" in
    short)
      printf '\\W'
      ;;
    repo)
      root=$(git rev-parse --show-toplevel 2>/dev/null) || {
        printf '\\w'
        return
      }
      rel=${PWD#"$root"}
      rel=${rel#/}
      text="$(basename -- "$root")"
      [[ -n "$rel" ]] && text+="/$rel"
      __cm_prompt_escape "$text"
      ;;
    *)
      printf '\\w'
      ;;
  esac
}

__cm_git_branch_name() {
  git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null
}

__cm_git_info() {
  [[ "$__cm_show_git" == yes ]] || return
  local branch status line x y staged=0 changed=0 untracked=0 conflicted=0 ahead=0 behind=0 dirty=0
  branch=$(__cm_git_branch_name) || return
  [[ -n "$branch" ]] || return

  if [[ "$__cm_git_detail" == branch ]]; then
    printf '%s\t%s' "$(__cm_prompt_escape "$branch")" "$__cm_green"
    return
  fi

  status=$(git status --porcelain=v1 --branch --ignore-submodules=dirty 2>/dev/null) || return
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    if [[ "$line" == '## '* ]]; then
      [[ "$line" =~ ahead[[:space:]]+([0-9]+) ]] && ahead=${BASH_REMATCH[1]}
      [[ "$line" =~ behind[[:space:]]+([0-9]+) ]] && behind=${BASH_REMATCH[1]}
      continue
    fi
    if [[ "$line" == '??'* ]]; then
      ((untracked++))
      continue
    fi
    case "${line:0:2}" in
      DD|AU|UD|UA|DU|AA|UU) ((conflicted++)) ;;
    esac
    x=${line:0:1}
    y=${line:1:1}
    [[ "$x" != ' ' && "$x" != '?' ]] && ((staged++))
    [[ "$y" != ' ' && "$y" != '?' ]] && ((changed++))
  done <<< "$status"

  local text color
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
  printf '%s\t%s' "$text" "$color"
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
    printf '%dm%02ds' "$minutes" "$rest"
  else
    printf '%ds' "$seconds"
  fi
}

__cm_runtime_text() {
  local parts=() duration time_value
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
  ((${#parts[@]})) || return 1
  local IFS='  '
  __cm_prompt_escape "${parts[*]}"
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
  printf '%s' "$ps"
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

  runtime=$(__cm_runtime_text) && {
    ps+="$(__cm_separator "$current_bg" "$__cm_surface0")"
    ps+="$(__cm_bgfg "$__cm_surface0" "$__cm_subtext") ${runtime} "
    current_bg=$__cm_surface0
  }

  ps+="$(__cm_separator "$current_bg")"
  __cm_prompt_head=$ps
}

__cm_visible_length() {
  local s=${1@P}
  s=${s//$'\001'/}
  s=${s//$'\002'/}
  while [[ $s == *$'\e['* ]]; do
    local before=${s%%$'\e['*}
    local after=${s#*$'\e['}
    after=${after#*m}
    s="${before}${after}"
  done
  printf '%s' "${#s}"
}

__cm_with_right_fill() {
  local left=$1 right=$2 cols left_w right_w pad fill_char fill
  cols=${COLUMNS:-80}
  if [[ -z "$right" ]]; then
    printf '%s' "$left"
    return
  fi
  left_w=$(__cm_visible_length "$left")
  right_w=$(__cm_visible_length "$right")
  pad=$(( cols - left_w - right_w - 2 ))
  if (( pad > 2 )); then
    if [[ "$__cm_charset" == ascii ]]; then
      fill_char='-'
    else
      fill_char='─'
    fi
    fill=$(printf "%${pad}s" '' | sed "s/ /${fill_char}/g")
    printf '%s %s%s%s %s' "$left" "$(__cm_fg "$__cm_overlay0")" "$fill" "$__cm_reset" "$right"
  else
    printf '%s  %s' "$left" "$right"
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
  runtime=$(__cm_runtime_text) && ps+=" $(__cm_fg "$__cm_subtext")${runtime}${__cm_reset}"
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
  local runtime
  runtime=$(__cm_runtime_text) && ps+=" $(__cm_fg "$__cm_subtext")${runtime}${__cm_reset}"
  __cm_prompt_head=$ps
}

__cm_prompt() {
  local last=$? now prompt_col prompt_mark status_text bottom runtime
  __cm_in_prompt=1
  now=${SECONDS:-0}
  __cm_last_duration=$((now - __cm_cmd_start))
  __cm_load_config

  if (( last == 0 )); then
    prompt_col=$__cm_prompt_color
  else
    prompt_col=$__cm_red
    [[ "$__cm_show_status" == yes ]] && status_text=" ${__cm_fail_mark} ${last}"
  fi
  prompt_mark="$(__cm_fg "$prompt_col" bold)${__cm_prompt_char}${status_text}${__cm_reset} "

  case "$__cm_prompt_style" in
    lean) __cm_lean_head ;;
    classic) __cm_classic_head ;;
    pure) __cm_pure_head ;;
    minimal) __cm_minimal_head ;;
    *) __cm_rainbow_head ;;
  esac

  if [[ "$__cm_prompt_style" == lean && "$__cm_prompt_layout" == two_line ]]; then
    bottom="$(__cm_fg "$__cm_prompt_color" bold)${__cm_frame_bottom}${__cm_reset} ${prompt_mark}"
    PS1="${__cm_prompt_head}\n${bottom}"
  elif [[ "$__cm_prompt_layout" == one_line && "$__cm_prompt_style" != pure ]]; then
    PS1="${__cm_prompt_head} ${prompt_mark}"
  else
    PS1="${__cm_prompt_head}\n${prompt_mark}"
  fi

  [[ "$__cm_prompt_spacing" == sparse ]] && PS1="\n${PS1}"
  __cm_cmd_start=${SECONDS:-0}
  __cm_in_prompt=0
}

__cm_preexec() {
  [[ "$__cm_in_prompt" == 1 ]] && return
  case "$BASH_COMMAND" in
    __cm_prompt*|__cm_preexec*|__cm_load_config*|prmptwiz*|promptwiz*) return ;;
  esac
  __cm_cmd_start=${SECONDS:-0}
}

__cm_first_run
trap '__cm_preexec' DEBUG
PROMPT_COMMAND='__cm_prompt'
