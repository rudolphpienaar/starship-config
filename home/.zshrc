export TERM="xterm-256color"
# ==============================================================================
# Environment & User Exports
# ==============================================================================
export USERNAME=$(whoami)
export EDITOR="nvim"
export VISUAL="nvim"

# Colored man pages via less
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

# ==============================================================================
# Custom Aliases & Neovim/AstroNvim Environments
# ==============================================================================
alias avim="NVIM_APPNAME=astronvim nvim"
alias aview="NVIM_APPNAME=astronvim nvim -R"
if command -v lsd >/dev/null 2>&1; then
  alias ls="lsd"
  alias l="lsd -l"
  alias la="lsd -la"
  alias lt="lsd --tree"
fi

# ==============================================================================
# Color Palettes & Startup Scripts
# ==============================================================================
[[ -f ~/.ls_colours_bgblack ]] && source ~/.ls_colours_bgblack
[[ -f ~/.splash ]] && bash ~/.splash

# ==============================================================================
# History & Completion Configuration
# ==============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS

autoload -Uz compinit && compinit -d ~/.zcompdump
zstyle ':completion:*' menu select

# ==============================================================================
# External Tool Integrations (Broot, Atuin, Starship)
# ==============================================================================
[[ -f ~/.config/broot/launcher/bash/br ]] && source ~/.config/broot/launcher/bash/br
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# ==============================================================================
# Plugins (Autosuggestions & Syntax Highlighting)
# ==============================================================================
[[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ==============================================================================
# User Binaries & NVM Initialization
# ==============================================================================
export PATH="$HOME/.local/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# ==============================================================================
# Starship Prompt & Layout Toggle Management
# ==============================================================================

export STARSHIP_PILLS=${STARSHIP_PILLS:-"on"}
export STARSHIP_LAYOUT=${STARSHIP_LAYOUT:-"3line"}

_apply_starship_config() {
  if [[ "$STARSHIP_PILLS" == "off" ]]; then
    export STARSHIP_CONFIG="$HOME/.config/starship-nopills.toml"
  else
    export STARSHIP_CONFIG="$HOME/.config/starship-${STARSHIP_LAYOUT}.toml"
  fi
}

tp() {
  if [[ "$STARSHIP_PILLS" == "on" ]]; then
    STARSHIP_PILLS="off"
    echo "Pills: OFF"
  else
    STARSHIP_PILLS="on"
    echo "Pills: ON (Layout: ${STARSHIP_LAYOUT})"
  fi
  _apply_starship_config
}

tl() {
  if [[ "$STARSHIP_PILLS" != "on" ]]; then
    echo "Cannot toggle layout: pills are currently toggled OFF. Turn them on with 'tp'."
    return 1
  fi

  if [[ "$STARSHIP_LAYOUT" == "3line" ]]; then
    STARSHIP_LAYOUT="2line"
  else
    STARSHIP_LAYOUT="3line"
  fi

  echo "Layout: ${STARSHIP_LAYOUT}"
  _apply_starship_config
}

_apply_starship_config
command -v starship &>/dev/null && eval "$(starship init zsh)"
