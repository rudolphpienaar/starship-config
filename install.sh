#!/bin/sh
# Install the managed Zsh configuration into a home directory.
set -eu

NVM_VERSION="v0.39.7"
NODE_VERSION="24.11.1"
AUTOSUGGESTIONS_COMMIT="85919cd1ffa7d2d5412f6d3fe437ebdbeeec4fc5"
SYNTAX_HIGHLIGHTING_COMMIT="c4d95591843d49838b7ad30081e7aba3135a6703"

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
target_home=${HOME:?HOME must be set}
install_packages=true
install_external=true

usage() {
  cat <<'EOF'
Usage: ./install.sh [--home PATH] [--skip-packages] [--skip-external]

Installs the repository-managed Zsh files as symlinks. Existing differing files
are moved to a timestamped .install-backups directory in the target home.

  --home PATH        Install into PATH instead of the current user's home.
  --skip-packages    Do not install OS packages.
  --skip-external    Do not install NVM, Node, plugins, or Broot integration.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --home)
      [ "$#" -ge 2 ] || { echo "--home requires a path" >&2; exit 2; }
      target_home=$2
      shift 2
      ;;
    --skip-packages)
      install_packages=false
      shift
      ;;
    --skip-external)
      install_external=false
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

log() {
  printf '%s\n' "==> $*"
}

warn() {
  printf '%s\n' "Warning: $*" >&2
}

is_termux() {
  [ -n "${TERMUX_VERSION:-}" ] || [ "${PREFIX:-}" = "/data/data/com.termux/files/usr" ]
}

install_one_package() {
  package_name=$1
  case $package_manager in
    pacman) sudo pacman -S --needed "$package_name" || warn "could not install $package_name" ;;
    brew) brew install "$package_name" || warn "could not install $package_name" ;;
    apt) sudo apt-get install -y "$package_name" || warn "could not install $package_name" ;;
    termux) pkg install -y "$package_name" || warn "could not install $package_name" ;;
  esac
}

install_os_packages() {
  if is_termux; then
    package_manager=termux
    pkg update -y || warn "Termux package metadata could not be refreshed"
  elif command -v pacman >/dev/null 2>&1; then
    package_manager=pacman
  elif command -v apt-get >/dev/null 2>&1; then
    package_manager=apt
    sudo apt-get update || warn "apt package metadata could not be refreshed"
  elif command -v brew >/dev/null 2>&1; then
    package_manager=brew
  else
    warn "no supported package manager found; install the dependencies in README.md manually"
    return
  fi

  log "Installing core packages through $package_manager"
  for package_name in zsh git curl starship lsd neovim; do install_one_package "$package_name"; done
  case $package_manager in
    pacman)
      for package_name in atuin broot github-cli fortune-mod cpufetch neofetch; do install_one_package "$package_name"; done
      ;;
    brew)
      for package_name in atuin broot gh fortune neofetch; do install_one_package "$package_name"; done
      ;;
    apt)
      for package_name in atuin broot gh fortune-mod neofetch; do install_one_package "$package_name"; done
      ;;
    termux)
      for package_name in nodejs atuin broot gh fortune cpufetch neofetch; do install_one_package "$package_name"; done
      ;;
  esac
}

backup_dir=
link_file() {
  source_path=$1
  destination_path=$2
  destination_dir=$(dirname -- "$destination_path")
  mkdir -p "$destination_dir"

  if [ -L "$destination_path" ] && [ "$(readlink "$destination_path")" = "$source_path" ]; then
    return
  fi

  if [ -e "$destination_path" ] || [ -L "$destination_path" ]; then
    if [ -z "$backup_dir" ]; then
      backup_dir="$target_home/.install-backups/$(date +%Y%m%d-%H%M%S)"
      mkdir -p "$backup_dir"
    fi
    backup_path="$backup_dir${destination_path#"$target_home"}"
    mkdir -p "$(dirname -- "$backup_path")"
    log "Backing up $destination_path"
    mv "$destination_path" "$backup_path"
  fi

  log "Linking $destination_path"
  ln -s "$source_path" "$destination_path"
}

install_managed_files() {
  link_file "$repo_dir/home/.zshrc" "$target_home/.zshrc"
  link_file "$repo_dir/home/.splash" "$target_home/.splash"
  link_file "$repo_dir/home/.ls_colours_bgblack" "$target_home/.ls_colours_bgblack"
  for config_file in "$repo_dir"/home/.config/*; do
    link_file "$config_file" "$target_home/.config/$(basename -- "$config_file")"
  done
}

checkout_repo() {
  repo_url=$1
  destination=$2
  revision=$3
  if [ ! -d "$destination/.git" ]; then
    git clone "$repo_url" "$destination"
  fi
  git -C "$destination" fetch --tags origin
  git -C "$destination" checkout --detach "$revision"
}

install_external_tools() {
  if ! command -v git >/dev/null 2>&1; then
    warn "git is unavailable; skipping NVM and Zsh plugins"
    return
  fi

  if is_termux; then
    log "Using Termux's native nodejs package; skipping NVM"
  else
    log "Installing pinned NVM and Node"
    checkout_repo "https://github.com/nvm-sh/nvm.git" "$target_home/.nvm" "$NVM_VERSION"
    NVM_DIR="$target_home/.nvm"
    export NVM_DIR
    . "$NVM_DIR/nvm.sh"
    nvm install "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
  fi

  log "Installing pinned Zsh plugins"
  checkout_repo "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$target_home/.zsh/plugins/zsh-autosuggestions" "$AUTOSUGGESTIONS_COMMIT"
  checkout_repo "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "$target_home/.zsh/plugins/zsh-syntax-highlighting" "$SYNTAX_HIGHLIGHTING_COMMIT"

  if command -v broot >/dev/null 2>&1; then
    launcher_dir="$target_home/.config/broot/launcher/zsh"
    launcher_file="$launcher_dir/br"
    launcher_tmp="$launcher_file.tmp"
    mkdir -p "$launcher_dir"
    if broot --print-shell-function zsh >"$launcher_tmp"; then
      mv "$launcher_tmp" "$launcher_file"
    else
      rm -f "$launcher_tmp"
      warn "could not create Broot's shell launcher"
    fi
  fi
}

mkdir -p "$target_home"
if [ "$install_packages" = true ]; then
  install_os_packages
fi
install_managed_files
if [ "$install_external" = true ]; then
  install_external_tools
fi

log "Setup complete. Start a new Zsh session to use the configuration."
