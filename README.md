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

System-status pills show available/total RAM, the free-space percentage of the
current filesystem, and the one-minute load average. RAM and disk pills turn
yellow below 15% free and red below 5%; load turns yellow above 5 and red above
10. They work on Linux, Termux, and macOS without additional dependencies.

## Contents

- [Prompt controls](#prompt-controls)
- [Startup dashboard](#startup-dashboard)
- [Font setup](#font-setup)
  - [Linux](#linux)
  - [macOS](#macos)
  - [Termux](#termux)
- [Install](#install)
  - [Useful installer options](#useful-installer-options)
- [Managed files](#managed-files)
- [Verify](#verify)

## Prompt controls

`tp` toggles the environmental pills on and off.

`tl` switches between the two-line and three-line pill layouts. Use the
three-line layout when the pills would overflow a single line; `tl` is
available only while pills are enabled.

The default is the two-line pill layout.
In that layout, a horizontal rule connects the left prompt segments to the
right-side environmental pills. Every left segment group begins with a
Powerline arrow cap. The primary context always shows the operating system,
login name, hostname, and current directory before any Git status, for example
`❄️    rudolph   󰣀 callisto   ~`.

Directory paths retain up to eight path components in every layout. Longer
paths begin with `…/`; inside a Git repository, Starship also hides path
components above the repository root.

## Startup dashboard

Interactive terminals outside tmux open with a boxed dashboard showing machine
and session context before the first prompt:

- `console matrix`: hostname, login, terminal, kernel, architecture, and uptime
- `process board`: the ten processes currently using the most CPU
- `session index`: active logins reported by `finger` or `who`
- `temperature cities`: current conditions for Boston, New York City, Troy,
  New York, and Cape Town
- `calendar and time`: the current month beside a large clock when `toilet` or
  `figlet` is available
- optional CPUFetch plus Neofetch or Screenfetch system summaries
- `signal`: a fortune when the `fortune` command is available

Missing optional commands and unavailable feeds degrade gracefully. Weather
requests run in parallel with short connection and request timeouts, while the
dashboard waits for every city before rendering the panel.

Set `STARSHIP_SPLASH=off` to disable the dashboard. Individual slower or more
decorative sections can be disabled with `STARSHIP_SPLASH_WEATHER=off`,
`STARSHIP_SPLASH_FETCH=off`, and `STARSHIP_SPLASH_FORTUNE=off`.

## Font setup

For best results, use a font with Nerd Font glyph support. We recommend
`JetBrainsMonoNL Nerd Font`, the no-ligatures JetBrains Mono Nerd Font family.
It includes the Powerline and environmental glyphs used by this prompt.

### Linux

You can install the current JetBrains Mono Nerd Font release into your local
font directory and rebuild the Fontconfig cache:

```sh
mkdir -p ~/.local/share/fonts/JetBrainsMonoNL
curl -fLO https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xJf JetBrainsMono.tar.xz -C ~/.local/share/fonts/JetBrainsMonoNL \
  --wildcards '*JetBrainsMonoNLNerdFont*.ttf'
fc-cache -fv ~/.local/share/fonts
fc-match 'JetBrainsMonoNL Nerd Font'
```

### macOS

Homebrew installs the same Nerd Font family:

```sh
brew install --cask font-jetbrains-mono-nerd-font
```

### Termux

The Linux Fontconfig installation does not configure the Termux app's font.
Instead, extract the single-width NL font to Termux's expected `font.ttf`
location, then reload its settings:

```sh
mkdir -p ~/.termux
curl -fLo /tmp/JetBrainsMono.tar.xz https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xOJf /tmp/JetBrainsMono.tar.xz JetBrainsMonoNLNerdFontMono-Regular.ttf > ~/.termux/font.ttf
termux-reload-settings
```

For Linux and macOS terminals, select `JetBrainsMonoNL Nerd Font`. If the
terminal requires strict single-width glyphs, select `JetBrainsMonoNL Nerd Font
Mono` instead. Log out and back in before choosing the font so your desktop
session and terminal discover the refreshed font cache.

## Install

The configuration lives under `home/` and is installed into your home directory
as symlinks. Run the installer from a clone:

```sh
./install.sh
```

It detects Arch (`pacman`), macOS/Homebrew, Debian/Ubuntu (`apt`), and Termux
on Android (`pkg`). Native Linux package managers take precedence when a
Linuxbrew installation is also present. The installer tries to install core
shell tools and optional integrations, then installs Node, Zsh plugins, and
the managed symlinks. Other supported platforms use pinned NVM and Node.
Termux uses `pkg` directly, installs its native `nodejs` package, and never
requires `sudo` or NVM.

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
- `~/.config/starship-theme.zsh`
- `~/.config/starship-gh-status.sh`
- `~/.config/starship-system-status.sh`

Optional visual integrations are Atuin, Broot, GitHub CLI, Fortune, CPUFetch,
Neofetch, Toilet, and Figlet. Missing optional tools are guarded so Zsh still
starts normally.

The default Node version is pinned in `.nvmrc`; NVM and the two Zsh plugins
are pinned in `install.sh`.

## Verify

```sh
./tests/test-install.sh
```

_-30-_
