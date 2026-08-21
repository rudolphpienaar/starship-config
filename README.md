# Powerlevel10k-inspired Starship prompt

This project began as a Starship recreation of the Powerlevel10k Zsh prompt.
It keeps the familiar powerline-style context on the left, while making the
prompt straightforward to install and customize as ordinary dotfiles.

Along the way, it developed its own visual language: rounded environmental
"pills" on the right. They surface active tools, cloud contexts, status, and
other useful tokens without crowding the primary directory and Git context.

The GitHub pill is reactive. It is green when `gh auth status` succeeds and
red when it fails, so an expired or missing GitHub CLI login is visible before
you need it.

## Prompt controls

`tp` toggles the environmental pills on and off.

`tl` switches between the two-line and three-line pill layouts. Use the
three-line layout when the pills would overflow a single line; `tl` is
available only while pills are enabled.

The default is the three-line pill layout.

## Font setup

Use `JetBrainsMonoNL Nerd Font`, not the unpatched upstream JetBrains Mono.
The `NL` family is the no-ligatures variant, and the Nerd Font patch supplies
the prompt's Powerline and environment glyphs.

On Linux, install the current JetBrains Mono Nerd Font release into your local
font directory and rebuild the Fontconfig cache:

```sh
mkdir -p ~/.local/share/fonts/JetBrainsMonoNL
curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xJf JetBrainsMono.tar.xz -C ~/.local/share/fonts/JetBrainsMonoNL \
  --wildcards '*JetBrainsMonoNLNerdFont*.ttf'
fc-cache -fv ~/.local/share/fonts
fc-match 'JetBrainsMonoNL Nerd Font'
```

Set your terminal's font family to `JetBrainsMonoNL Nerd Font`. If the terminal
requires strict single-width glyphs, use `JetBrainsMonoNL Nerd Font Mono`
instead. Log out and back in before selecting the font so your desktop session
and terminal discover the refreshed font cache.

## Install

The configuration lives under `home/` and is installed into your home directory
as symlinks. Run the installer from a clone:

```sh
./install.sh
```

It detects Arch (`pacman`), macOS/Homebrew, Debian/Ubuntu (`apt`), and Termux
on Android (`pkg`). It tries to install core shell tools and optional
integrations, then installs Node, Zsh plugins, and the managed symlinks. Other
supported platforms use pinned NVM and Node. Termux uses `pkg` directly,
installs its native `nodejs` package, and never requires `sudo` or NVM.

Authentication and account state for GitHub, Atuin, and cloud providers remain
local to each machine. Existing files that differ from a managed symlink move
to `~/.install-backups/<timestamp>/` before linking.

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

Optional visual integrations are Atuin, Broot, GitHub CLI, Fortune, CPUFetch,
and Neofetch. Missing optional tools are guarded so Zsh still starts normally.

The default Node version is pinned in `.nvmrc`; NVM and the two Zsh plugins
are pinned in `install.sh`.

## Verify

```sh
./tests/test-install.sh
```
