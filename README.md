# Portable Zsh + Starship setup

This repository reproduces the Zsh prompt and startup environment from this
machine. It keeps the configuration in `home/` and installs it into a user
home directory as symlinks.

## Install

Run the installer from a clone:

```sh
./install.sh
```

It detects Arch (`pacman`), macOS/Homebrew, and Debian/Ubuntu (`apt`) and tries
to install the core shell tools plus optional integrations. It then installs
pinned NVM, Node, Zsh plugins, and the managed symlinks. Authentication and
account state for GitHub, Atuin, and cloud providers remain local to each
machine.

Existing files that differ from a managed symlink are moved to
`~/.install-backups/<timestamp>/` before linking.

### Useful installer options

```sh
./install.sh --skip-packages
./install.sh --skip-external
./install.sh --home /path/to/test-home --skip-packages --skip-external
```

## Managed files

- `~/.zshrc`, `~/.splash`, and `~/.ls_colours_bgblack`
- `~/.config/starship.toml` and the two- and three-line variants
- `~/.config/starship-nopills.toml`
- `~/.config/starship-gh-status.sh`

The prompt needs a Nerd Font for its icons. Optional visual integrations are
Atuin, Broot, GitHub CLI, Fortune, CPUFetch, and Neofetch. Missing optional
tools are guarded so that Zsh still starts normally.

## Prompt controls

- `tp` toggles pill segments on and off.
- `tl` switches the pill prompt between the two-line and three-line layouts.

The default is the three-line pill layout. The default Node version is pinned
in `.nvmrc`; NVM and the two Zsh plugins are pinned in `install.sh`.

## Verify

```sh
./tests/test-install.sh
```
