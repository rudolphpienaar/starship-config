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
  .config/starship-gh-status.sh; do
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
sh -n "$test_home/.splash"
sh -n "$test_home/.config/starship-gh-status.sh"
zsh -n "$test_home/.zshrc"
[ "$(grep -c 'starship init zsh' "$test_home/.zshrc")" -eq 1 ] || {
  echo "expected exactly one Starship initialization" >&2
  exit 1
}
for config_file in "$test_home"/.config/starship*.toml; do
  STARSHIP_CONFIG="$config_file" starship module character >/dev/null
done

mkdir "$test_home/bin"
for command_name in bash grep hostname mv uname wc whoami; do
  ln -s "$(command -v "$command_name")" "$test_home/bin/$command_name"
done
zsh_path=$(command -v zsh)
minimal_stderr="$test_home/minimal-zsh.stderr"
HOME="$test_home" PATH="$test_home/bin" "$zsh_path" -fc 'unset STARSHIP_CONFIG STARSHIP_LAYOUT STARSHIP_PILLS; . "$HOME/.zshrc"; [ "$STARSHIP_CONFIG" = "$HOME/.config/starship-3line.toml" ]; whence -w tp; whence -w tl' >/dev/null 2>"$minimal_stderr"
[ ! -s "$minimal_stderr" ] || {
  cat "$minimal_stderr" >&2
  exit 1
}
