#!/bin/sh
# Catppuccin prompt setup wizard for the Command plugin.

config=${COMMAND_PROMPT_CONFIG:-"$HOME/.config/obsidian-command/prompt.conf"}

cm_reset=$(printf '\033[0m')
cm_bold=$(printf '\033[1m')
cm_dim=$(printf '\033[2m')
cm_mauve=$(printf '\033[38;2;203;166;247m')
cm_blue=$(printf '\033[38;2;137;180;250m')
cm_peach=$(printf '\033[38;2;250;179;135m')
cm_green=$(printf '\033[38;2;166;227;161m')
cm_yellow=$(printf '\033[38;2;249;226;175m')
cm_red=$(printf '\033[38;2;243;139;168m')
cm_muted=$(printf '\033[38;2;166;173;200m')

style=lean
layout=two_line
spacing=sparse
charset=nerd
show_os=yes
show_user=yes
show_host=yes
show_git=yes
git_detail=status
show_status=no
show_duration=no
duration_threshold=2
show_time=yes
time_format=24h
right_prompt=yes
prompt_char='❯'
accent=mauve
dir_style=full

load_config() {
  [ -f "$config" ] || return
  while IFS='=' read -r key value || [ -n "$key" ]; do
    case "$key" in
      COMMAND_PROMPT_STYLE) style=$value ;;
      COMMAND_PROMPT_LAYOUT) layout=$value ;;
      COMMAND_PROMPT_SPACING) spacing=$value ;;
      COMMAND_PROMPT_CHARSET) charset=$value ;;
      COMMAND_PROMPT_SHOW_OS) show_os=$value ;;
      COMMAND_PROMPT_SHOW_USER) show_user=$value ;;
      COMMAND_PROMPT_SHOW_HOST) show_host=$value ;;
      COMMAND_PROMPT_SHOW_GIT) show_git=$value ;;
      COMMAND_PROMPT_GIT_DETAIL) git_detail=$value ;;
      COMMAND_PROMPT_SHOW_STATUS) show_status=$value ;;
      COMMAND_PROMPT_SHOW_DURATION) show_duration=$value ;;
      COMMAND_PROMPT_DURATION_THRESHOLD) duration_threshold=$value ;;
      COMMAND_PROMPT_SHOW_TIME) show_time=$value ;;
      COMMAND_PROMPT_TIME_FORMAT) time_format=$value ;;
      COMMAND_PROMPT_RIGHT_PROMPT) right_prompt=$value ;;
      COMMAND_PROMPT_PROMPT_CHAR) prompt_char=${value:-❯} ;;
      COMMAND_PROMPT_ACCENT) accent=$value ;;
      COMMAND_PROMPT_DIR_STYLE) dir_style=$value ;;
    esac
  done < "$config"

  [ "$style" = powerline ] && style=rainbow
  case "$style" in lean|classic|rainbow|pure|minimal) ;; *) style=rainbow ;; esac
  case "$layout" in one_line|two_line) ;; *) layout=two_line ;; esac
  case "$spacing" in compact|sparse) ;; *) spacing=sparse ;; esac
  case "$charset" in nerd|unicode|ascii) ;; *) charset=nerd ;; esac
  case "$show_os" in yes|no) ;; *) show_os=yes ;; esac
  case "$show_user" in yes|no) ;; *) show_user=yes ;; esac
  case "$show_host" in yes|no) ;; *) show_host=yes ;; esac
  case "$show_git" in yes|no) ;; *) show_git=yes ;; esac
  case "$git_detail" in branch|status) ;; *) git_detail=status ;; esac
  case "$show_status" in yes|no) ;; *) show_status=no ;; esac
  case "$show_duration" in yes|no) ;; *) show_duration=no ;; esac
  case "$duration_threshold" in ''|*[!0-9]*) duration_threshold=2 ;; esac
  case "$show_time" in yes|no) ;; *) show_time=yes ;; esac
  case "$time_format" in 12h|24h) ;; *) time_format=24h ;; esac
  case "$right_prompt" in yes|no) ;; *) right_prompt=yes ;; esac
  case "$accent" in mauve|blue|green|peach|rosewater) ;; *) accent=mauve ;; esac
  case "$dir_style" in full|short|repo) ;; *) dir_style=full ;; esac
}

clear_screen() {
  if command -v clear >/dev/null 2>&1; then
    clear
  else
    printf '\033[H\033[2J'
  fi
}

pause() {
  printf '%sPress ENTER to continue.%s' "$cm_muted" "$cm_reset"
  IFS= read -r _unused || :
}

abort_wizard() {
  printf '\n%sNo changes written.%s\n' "$cm_yellow" "$cm_reset"
  exit 1
}

option_value() {
  printf '%s' "${1%%|*}"
}

option_label() {
  rest=${1#*|}
  printf '%s' "${rest%%|*}"
}

option_desc() {
  rest=${1#*|}
  desc=${rest#*|}
  [ "$desc" = "$rest" ] && desc=
  printf '%s' "$desc"
}

choose() {
  title=$1
  default_value=$2
  shift 2

  printf '\n%s%s%s\n' "$cm_bold" "$title" "$cm_reset"
  i=1
  default_index=1
  for option do
    value=$(option_value "$option")
    label=$(option_label "$option")
    desc=$(option_desc "$option")
    marker=' '
    if [ "$value" = "$default_value" ]; then
      marker='*'
      default_index=$i
    fi
    printf '  %s%d) %s%s%s' "$marker" "$i" "$cm_bold" "$label" "$cm_reset"
    [ -n "$desc" ] && printf '  %s%s%s' "$cm_muted" "$desc" "$cm_reset"
    printf '\n'
    i=$((i + 1))
  done

  while :; do
    printf '%sChoice [%s], q to quit: %s' "$cm_muted" "$default_index" "$cm_reset"
    IFS= read -r answer || answer=
    [ -z "$answer" ] && answer=$default_index
    case "$answer" in
      q|Q) abort_wizard ;;
      *[!0-9]*|'') printf '%sEnter a number.%s\n' "$cm_yellow" "$cm_reset" ;;
      *)
        if [ "$answer" -ge 1 ] && [ "$answer" -lt "$i" ]; then
          n=1
          for option do
            if [ "$n" = "$answer" ]; then
              choice=$(option_value "$option")
              return 0
            fi
            n=$((n + 1))
          done
        fi
        printf '%sChoose 1-%d.%s\n' "$cm_yellow" $((i - 1)) "$cm_reset"
        ;;
    esac
  done
}

sample_prompt_char() {
  case "$charset" in
    ascii) printf '>' ;;
    *) printf '%s' "$prompt_char" ;;
  esac
}

sample_branch() {
  case "$charset" in
    nerd) printf ' main +2 ~1 ?3' ;;
    unicode) printf 'git main +2 ~1 ?3' ;;
    *) printf 'git:main +2 ~1 ?3' ;;
  esac
}

sample_identity() {
  os_text=
  if [ "$show_os" = yes ]; then
    case "$charset" in
      nerd) os_text='' ;;
      ascii) os_text='fedora' ;;
      *) os_text='linux' ;;
    esac
  fi
  if [ "$show_user" = yes ] && [ "$show_host" = yes ]; then
    printf '%s%s' "${os_text:+$os_text }" 'alex@vault'
  elif [ "$show_user" = yes ]; then
    printf '%s%s' "${os_text:+$os_text }" 'alex'
  else
    printf '%s' "$os_text"
  fi
}

sample_path() {
  case "$dir_style" in
    short) printf 'notes' ;;
    repo) printf 'projects/example' ;;
    *) printf '~/projects/example' ;;
  esac
}

print_preview() {
  pchar=$(sample_prompt_char)
  git_text=$(sample_branch)
  id_text=$(sample_identity)
  path_text=$(sample_path)
  [ "$show_git" = yes ] || git_text=
  right_text=
  [ "$show_duration" = yes ] && right_text='took 5s'
  [ "$show_time" = yes ] && right_text="${right_text}${right_text:+  }16:23"
  status_text=
  [ "$show_status" = yes ] && status_text=' ✘ 2'

  printf '\n%sPreview%s\n' "$cm_bold" "$cm_reset"
  case "$style" in
    lean)
      if [ "$layout" = two_line ]; then
        printf '  %s╭─%s %s%s%s %s%s%s %s%s%s\n' "$cm_mauve" "$cm_reset" "$cm_mauve" "$id_text" "$cm_reset" "$cm_peach" "$path_text" "$cm_reset" "$cm_green" "$git_text" "$cm_reset"
        printf '  %s╰─%s %s%s%s%s %s%s%s\n' "$cm_mauve" "$cm_reset" "$cm_mauve" "$pchar" "$status_text" "$cm_reset" "$cm_muted" "$right_text" "$cm_reset"
      else
        printf '  %s%s%s %s%s%s %s%s%s %s%s%s%s %s%s%s\n' "$cm_mauve" "$id_text" "$cm_reset" "$cm_peach" "$path_text" "$cm_reset" "$cm_green" "$git_text" "$cm_reset" "$cm_mauve" "$pchar" "$status_text" "$cm_reset" "$cm_muted" "$right_text" "$cm_reset"
      fi
      ;;
    classic)
      printf '  %s%s%s  %s%s%s  %s%s%s  %s%s%s%s %s%s%s\n' "$cm_mauve" "$id_text" "$cm_reset" "$cm_peach" "$path_text" "$cm_reset" "$cm_green" "$git_text" "$cm_reset" "$cm_mauve" "$pchar" "$status_text" "$cm_reset" "$cm_muted" "$right_text" "$cm_reset"
      ;;
    pure)
      printf '  %s%s%s %s%s%s %s%s%s\n' "$cm_blue" "$path_text" "$cm_reset" "$cm_muted" "$git_text" "$cm_reset" "$cm_muted" "$right_text" "$cm_reset"
      printf '  %s%s%s%s\n' "$cm_mauve" "$pchar" "$status_text" "$cm_reset"
      ;;
    minimal)
      printf '  %s%s%s %s%s%s %s%s%s%s\n' "$cm_peach" "$path_text" "$cm_reset" "$cm_green" "$git_text" "$cm_reset" "$cm_mauve" "$pchar" "$status_text" "$cm_reset"
      ;;
    *)
      if [ "$charset" = ascii ]; then
        printf '  %s %s %s %s %s %s%s%s\n' "$id_text" "$path_text" "$git_text" "$pchar" "$right_text" "$cm_red" "$status_text" "$cm_reset"
      else
        printf '  %s %s  %s %s  %s %s %s %s%s%s %s%s%s\n' "$cm_mauve" "$id_text" "$cm_peach" "$path_text" "$cm_green" "$git_text" "$cm_reset" "$cm_mauve" "$pchar" "$status_text" "$cm_reset" "$cm_muted" "$right_text" "$cm_reset"
      fi
      ;;
  esac
}

write_config() {
  dir=$(dirname "$config")
  mkdir -p "$dir" 2>/dev/null || {
    printf '%sCould not create %s%s\n' "$cm_red" "$dir" "$cm_reset" >&2
    exit 1
  }

  tmp="${config}.$$"
  {
    printf '# Generated by Command Prompt Wizard.\n'
    printf 'COMMAND_PROMPT_VERSION=2\n'
    printf 'COMMAND_PROMPT_STYLE=%s\n' "$style"
    printf 'COMMAND_PROMPT_LAYOUT=%s\n' "$layout"
    printf 'COMMAND_PROMPT_SPACING=%s\n' "$spacing"
    printf 'COMMAND_PROMPT_CHARSET=%s\n' "$charset"
    printf 'COMMAND_PROMPT_SHOW_OS=%s\n' "$show_os"
    printf 'COMMAND_PROMPT_SHOW_USER=%s\n' "$show_user"
    printf 'COMMAND_PROMPT_SHOW_HOST=%s\n' "$show_host"
    printf 'COMMAND_PROMPT_SHOW_GIT=%s\n' "$show_git"
    printf 'COMMAND_PROMPT_GIT_DETAIL=%s\n' "$git_detail"
    printf 'COMMAND_PROMPT_SHOW_STATUS=%s\n' "$show_status"
    printf 'COMMAND_PROMPT_SHOW_DURATION=%s\n' "$show_duration"
    printf 'COMMAND_PROMPT_DURATION_THRESHOLD=%s\n' "$duration_threshold"
    printf 'COMMAND_PROMPT_SHOW_TIME=%s\n' "$show_time"
    printf 'COMMAND_PROMPT_TIME_FORMAT=%s\n' "$time_format"
    printf 'COMMAND_PROMPT_RIGHT_PROMPT=%s\n' "$right_prompt"
    printf 'COMMAND_PROMPT_PROMPT_CHAR=%s\n' "$prompt_char"
    printf 'COMMAND_PROMPT_ACCENT=%s\n' "$accent"
    printf 'COMMAND_PROMPT_DIR_STYLE=%s\n' "$dir_style"
  } >"$tmp" || {
    printf '%sCould not write %s%s\n' "$cm_red" "$tmp" "$cm_reset" >&2
    exit 1
  }

  mv "$tmp" "$config" || {
    rm -f "$tmp"
    printf '%sCould not replace %s%s\n' "$cm_red" "$config" "$cm_reset" >&2
    exit 1
  }
}

clear_screen
printf '%s%sCommand Prompt Wizard%s\n' "$cm_bold" "$cm_mauve" "$cm_reset"
printf '%sCatppuccin Mocha prompt setup for this Obsidian vault.%s\n' "$cm_muted" "$cm_reset"
printf '%sWrites: %s%s\n' "$cm_muted" "$config" "$cm_reset"
if [ ! -f "$config" ]; then
  print_preview
  printf '\n%sNo prompt config exists yet.%s\n' "$cm_yellow" "$cm_reset"
  choose "First run setup" defaults \
    "defaults|Use shipped defaults|Install the repo default prompt shown above." \
    "configure|Configure now|Open the full prompt wizard."
  if [ "$choice" = defaults ]; then
    write_config
    printf '\n%sSaved shipped prompt defaults.%s\n' "$cm_green" "$cm_reset"
    exit 0
  fi
else
  load_config
  printf '%sExisting config will be replaced only after final confirmation.%s\n' "$cm_yellow" "$cm_reset"
fi
printf '\n%sThis follows the modern prompt model: pick a visual preset, test glyph support, then choose modules.%s\n' "$cm_dim" "$cm_reset"
pause

clear_screen
printf '%sGlyph Check%s\n' "$cm_bold" "$cm_reset"
printf 'Powerline separators: %s %s\n' "$cm_mauve" "$cm_reset"
choose "Do the separators render as clean triangles, with no boxes or gaps?" \
  "$( [ "$charset" = ascii ] && printf no || printf yes )" \
  "yes|Yes|Use powerline-capable presets." \
  "no|No|Use portable separators."
powerline_ok=$choice

if [ "$powerline_ok" = yes ]; then
  printf '\nNerd Font symbols: %s 󰊢 %s\n' "$cm_green" "$cm_reset"
  choose "Do the branch and tool icons render correctly?" \
    "$( [ "$charset" = nerd ] && printf yes || printf no )" \
    "yes|Yes|Use Nerd Font symbols." \
    "no|No|Use Unicode text fallbacks."
  [ "$choice" = yes ] && charset=nerd || charset=unicode
else
  charset=ascii
fi

clear_screen
printf '%sStyle Presets%s\n' "$cm_bold" "$cm_reset"
printf '  %sLean%s      Framed p10k-style prompt with strong scanability.\n' "$cm_mauve" "$cm_reset"
printf '  %sClassic%s   Colored text, no heavy separators.\n' "$cm_peach" "$cm_reset"
printf '  %sRainbow%s   Catppuccin powerline blocks inspired by Starship presets.\n' "$cm_green" "$cm_reset"
printf '  %sPure%s      Two-line minimal prompt with context above input.\n' "$cm_blue" "$cm_reset"
printf '  %sMinimal%s   Smallest prompt that still shows path and git.\n' "$cm_muted" "$cm_reset"
choose "Prompt style" "$style" \
  "lean|Lean|p10k-inspired frame." \
  "classic|Classic|Readable colored text." \
  "rainbow|Rainbow|Catppuccin powerline segments." \
  "pure|Pure|Minimal two-line flow." \
  "minimal|Minimal|Compact path + git."
style=$choice
print_preview
pause

choose "Prompt layout" "$layout" \
  "two_line|Two lines|More room for commands." \
  "one_line|One line|Denser scrollback."
layout=$choice

choose "Prompt spacing" "$spacing" \
  "compact|Compact|No blank line before the prompt." \
  "sparse|Sparse|Add a blank line before each prompt."
spacing=$choice

choose "Directory display" "$dir_style" \
  "full|Full path|Use home-collapsed path." \
  "short|Current folder|Show only the leaf directory." \
  "repo|Repository relative|Show repo name plus relative path when possible."
dir_style=$choice

identity_default=directory
[ "$show_user" = yes ] && identity_default=user
[ "$show_user" = yes ] && [ "$show_host" = yes ] && identity_default=user_host
choose "Identity segment" "$identity_default" \
  "directory|No user|Start with the directory." \
  "user|User|Show username." \
  "user_host|User and host|Show username@host."
case "$choice" in
  user) show_user=yes; show_host=no ;;
  user_host) show_user=yes; show_host=yes ;;
  *) show_user=no; show_host=no ;;
esac

choose "Distro logo" "$show_os" \
  "yes|Show OS logo|Detect Linux distro and place its logo before identity." \
  "no|Hide OS logo|Do not show a distro mark."
show_os=$choice

git_default=off
[ "$show_git" = yes ] && git_default=$git_detail
choose "Git segment" "$git_default" \
  "status|Branch + status|Show staged, changed, untracked, ahead/behind." \
  "branch|Branch only|Fastest git display." \
  "off|Off|Hide git information."
case "$choice" in
  status) show_git=yes; git_detail=status ;;
  branch) show_git=yes; git_detail=branch ;;
  *) show_git=no; git_detail=branch ;;
esac

choose "Exit status" "$show_status" \
  "yes|Show failures|Display non-zero exit codes." \
  "no|Prompt color only|Only turn prompt character red."
show_status=$choice

choose "Command duration" "$show_duration" \
  "yes|Show slow commands|Display duration after the threshold." \
  "no|Off|Hide command duration."
show_duration=$choice
if [ "$show_duration" = yes ]; then
  choose "Duration threshold" "$duration_threshold" \
    "1|1 second|Useful for short commands." \
    "2|2 seconds|Balanced default." \
    "5|5 seconds|Only long-running commands."
  duration_threshold=$choice
fi

choose "Clock" "$show_time" \
  "no|Off|No clock in prompt." \
  "yes|On|Show current time."
show_time=$choice
if [ "$show_time" = yes ]; then
  choose "Clock format" "$time_format" \
    "24h|24-hour|16:23" \
    "12h|12-hour|04:23 PM"
  time_format=$choice
fi

choose "Right prompt" "$right_prompt" \
  "yes|Use when available|zsh places time/duration on the right; bash appends them." \
  "no|Inline only|Keep everything on the left."
right_prompt=$choice

default_char=$prompt_char
[ "$charset" = ascii ] && default_char='>'
choose "Prompt character" "$default_char" \
  "❯|❯|Modern angle." \
  "λ|λ|Lambda." \
  "$|$|Classic shell." \
  "➜|➜|Arrow." \
  ">|>|ASCII."
prompt_char=$choice

choose "Accent color" "$accent" \
  "mauve|Mauve|Catppuccin default." \
  "blue|Blue|Cooler prompt mark." \
  "green|Green|Quiet success tone." \
  "peach|Peach|Warmer prompt mark." \
  "rosewater|Rosewater|Softer highlight."
accent=$choice

clear_screen
printf '%sSummary%s\n' "$cm_bold" "$cm_reset"
print_preview
summary_git=$git_detail
[ "$show_git" = no ] && summary_git=off
printf '\n  Style: %s\n  Layout: %s, %s\n  Charset: %s\n  Identity: os=%s user=%s host=%s\n  Git: %s\n  Modules: status=%s duration=%s time=%s right=%s\n' \
  "$style" "$layout" "$spacing" "$charset" "$show_os" "$show_user" "$show_host" "$summary_git" "$show_status" "$show_duration" "$show_time" "$right_prompt"

choose "Save this prompt configuration?" yes \
  "yes|Save|Write prompt.conf and reload future prompts." \
  "no|Cancel|Leave existing config untouched."
[ "$choice" = yes ] || abort_wizard

write_config
printf '\n%sSaved prompt config.%s\n' "$cm_green" "$cm_reset"
