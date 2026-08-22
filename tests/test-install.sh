#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT HUP INT TERM

printf '%s\n' 'existing shell configuration' > "$test_home/.zshrc"
"$repo_dir/install.sh" --home "$test_home" --skip-packages --skip-external

for path in \
  .zshrc \
  .splash \
  .ls_colours_bgblack \
  .config/starship.toml \
  .config/starship-2line.toml \
  .config/starship-3line.toml \
  .config/starship-nopills.toml \
  .config/starship-theme.zsh \
  .config/starship-gh-status.sh \
  .config/starship-system-status.sh; do
  [ -L "$test_home/$path" ] || { echo "expected symlink: $path" >&2; exit 1; }
done

[ -f "$test_home/.install-backups"/*/.zshrc ] || { echo "expected .zshrc backup" >&2; exit 1; }
backup_count=$(find "$test_home/.install-backups" -type f | wc -l | tr -d ' ')
"$repo_dir/install.sh" --home "$test_home" --skip-packages --skip-external
[ "$(find "$test_home/.install-backups" -type f | wc -l | tr -d ' ')" = "$backup_count" ] || {
  echo "rerun created an unexpected backup" >&2
  exit 1
}

sh -n "$repo_dir/install.sh"
zsh -n "$test_home/.splash"
zsh -n "$test_home/.config/starship-theme.zsh"
sh -n "$test_home/.config/starship-gh-status.sh"
sh -n "$test_home/.config/starship-system-status.sh"
for status_name in ram disk load; do
  status_output=$("$test_home/.config/starship-system-status.sh" "$status_name")
  [ -n "$status_output" ] || {
    echo "expected $status_name status output" >&2
    exit 1
  }
  if [ "$status_name" = ram ]; then
    case $status_output in */*) ;; *) echo "expected free/total RAM output" >&2; exit 1 ;; esac
  fi
  matching_states=0
  for state_name in normal yellow red; do
    if "$test_home/.config/starship-system-status.sh" "$status_name-state" "$state_name"; then
      matching_states=$((matching_states + 1))
    fi
  done
  [ "$matching_states" -eq 1 ] || {
    echo "expected exactly one $status_name color state" >&2
    exit 1
  }
done
zsh -n "$test_home/.zshrc"
[ "$(grep -c 'starship init zsh' "$test_home/.config/starship-theme.zsh")" -eq 1 ] || {
  echo "expected exactly one Starship initialization" >&2
  exit 1
}
! grep -q "source $test_home" "$repo_dir/home/.zshrc" || {
  echo "managed .zshrc contains a machine-specific source line" >&2
  exit 1
}
for config_file in "$test_home"/.config/starship*.toml; do
  HOME="$test_home" XDG_CACHE_HOME="$test_home/.cache" STARSHIP_CONFIG="$config_file" \
    starship module character >/dev/null
done

mkdir "$test_home/bin"
for command_name in bash grep hostname mv uname wc whoami; do
  ln -s "$(command -v "$command_name")" "$test_home/bin/$command_name"
done
ln -s "$(command -v true)" "$test_home/bin/brew"
zsh_path=$(command -v zsh)
minimal_stderr="$test_home/minimal-zsh.stderr"
HOME="$test_home" PATH="$test_home/bin" "$zsh_path" -fc 'unset STARSHIP_CONFIG STARSHIP_LAYOUT STARSHIP_PILLS; . "$HOME/.zshrc"; [ "$STARSHIP_CONFIG" = "$HOME/.config/starship-2line.toml" ]; case ":$PATH:" in *":$HOME/arch/scripts:"*) ;; *) exit 1 ;; esac; whence -w tp; whence -w tl' >/dev/null 2>"$minimal_stderr"
[ ! -s "$minimal_stderr" ] || {
  cat "$minimal_stderr" >&2
  exit 1
}
HOME="$test_home" PATH="$test_home/bin" "$zsh_path" -fc '
  . "$HOME/.config/starship-theme.zsh"
  tl >/dev/null
  [ "$STARSHIP_CONFIG" = "$HOME/.config/starship-3line.toml" ]
  tp >/dev/null
  [ "$STARSHIP_CONFIG" = "$HOME/.config/starship-nopills.toml" ]
  ! tl >/dev/null
  tp >/dev/null
  [ "$STARSHIP_CONFIG" = "$HOME/.config/starship-3line.toml" ]
'

splash_output=$(HOME="$test_home" STARSHIP_SPLASH_WEATHER=off STARSHIP_SPLASH_FETCH=off \
  STARSHIP_SPLASH_FORTUNE=off TERM=xterm-256color \
  "$zsh_path" -fic '. "$HOME/.splash"' 2>/dev/null)
for section_name in 'console matrix' 'process board' 'session index' \
  'temperature cities' 'calendar and time' 'signal'; do
  printf '%s\n' "$splash_output" | grep -F "$section_name" >/dev/null || {
    echo "expected splash section: $section_name" >&2
    exit 1
  }
done
[ -z "$(HOME="$test_home" STARSHIP_SPLASH=off TERM=xterm-256color "$zsh_path" -fic '. "$HOME/.splash"' 2>/dev/null)" ] || {
  echo "disabled splash produced output" >&2
  exit 1
}
[ -z "$(HOME="$test_home" TMUX=1 TERM=xterm-256color "$zsh_path" -fic '. "$HOME/.splash"' 2>/dev/null)" ] || {
  echo "tmux splash produced output"
  exit 1
}
HOME="$test_home" STARSHIP_SPLASH_WEATHER=off STARSHIP_SPLASH_FETCH=off \
  STARSHIP_SPLASH_FORTUNE=off TERM=xterm-256color \
  "$zsh_path" -fic '
    . "$HOME/.splash" >/dev/null
    for helper_name in _starship_splash_main _starship_splash_rule \
      _starship_splash_footer _starship_splash_box_line \
      _starship_splash_box_stream; do
      ! whence "$helper_name" >/dev/null 2>&1 || exit 1
    done
  ' 2>/dev/null

termux_bin="$test_home/termux-bin"
termux_home="$test_home/termux-home"
termux_package_log="$test_home/termux-packages.log"
mkdir "$termux_bin"
printf '%s\n' '#!/bin/sh' 'printf "%s\\n" "$*" >> "$TEST_PACKAGE_LOG"' > "$termux_bin/pkg"
printf '%s\n' '#!/bin/sh' 'printf "sudo %s\\n" "$*" >> "$TEST_PACKAGE_LOG"' 'exit 99' > "$termux_bin/sudo"
printf '%s\n' '#!/bin/sh' 'if [ "$1" = clone ]; then mkdir -p "$3/.git"; fi' 'exit 0' > "$termux_bin/git"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$termux_bin/broot"
chmod +x "$termux_bin/pkg"
chmod +x "$termux_bin/sudo"
chmod +x "$termux_bin/git"
chmod +x "$termux_bin/broot"
TERMUX_VERSION=0.118.0 PREFIX=/data/data/com.termux/files/usr \
  TEST_PACKAGE_LOG="$termux_package_log" PATH="$termux_bin:$PATH" \
  "$repo_dir/install.sh" --home "$termux_home" >/dev/null
grep -Fx 'update -y' "$termux_package_log" >/dev/null
grep -Fx 'install -y starship' "$termux_package_log" >/dev/null
grep -Fx 'install -y nodejs' "$termux_package_log" >/dev/null
grep -Fx 'install -y toilet' "$termux_package_log" >/dev/null
grep -Fx 'install -y util-linux' "$termux_package_log" >/dev/null
[ ! -d "$termux_home/.nvm" ] || { echo "Termux install used NVM" >&2; exit 1; }
! grep -q '^sudo ' "$termux_package_log"
[ -L "$termux_home/.zshrc" ] || { echo "Termux install did not link .zshrc" >&2; exit 1; }
