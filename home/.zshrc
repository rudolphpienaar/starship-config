export TERM="xterm-256color"
# ==============================================================================
# Environment & User Exports
# ==============================================================================
export EDITOR="nvim"
export VISUAL="nvim"

# Homebrew isn't always added to PATH for non-login shells. Bootstrap its
# standard locations before initializing any tools installed through it.
if ! command -v brew >/dev/null 2>&1; then
  for brew_prefix in /home/linuxbrew/.linuxbrew /opt/homebrew /usr/local; do
    if [[ -x "$brew_prefix/bin/brew" ]]; then
      export PATH="$brew_prefix/bin:$brew_prefix/sbin:$PATH"
      export HOMEBREW_PREFIX="$brew_prefix"
      export HOMEBREW_CELLAR="$brew_prefix/Cellar"
      export HOMEBREW_REPOSITORY="$brew_prefix/Homebrew"
      break
    fi
  done
fi

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
[[ -f ~/.splash ]] && source ~/.splash

# ==============================================================================
# History & Completion Configuration
# ==============================================================================
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS

if [[ -o interactive ]]; then
  autoload -Uz compinit && compinit -d ~/.zcompdump
fi
zstyle ':completion:*' menu select

# ==============================================================================
# External Tool Integrations (Broot, Atuin, Starship)
# ==============================================================================
if [[ -f ~/.config/broot/launcher/zsh/br ]]; then
  source ~/.config/broot/launcher/zsh/br
elif [[ -f ~/.config/broot/launcher/bash/br ]]; then
  source ~/.config/broot/launcher/bash/br
fi
command -v atuin &>/dev/null && eval "$(atuin init zsh)"

# ==============================================================================
# Plugins (Autosuggestions & Syntax Highlighting)
# ==============================================================================
[[ -f ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ==============================================================================
# User Binaries & NVM Initialization
# ==============================================================================
_starship_legacy_paths() {
  local BIT DIR ACCESS arch b_64 b_NT root
  b_64=$(uname -a | grep x86_64 | wc -l)
  if (( b_64 )); then
    BIT=64
  else
    BIT=32
  fi

  for DIR in bin lib scripts; do
    for ACCESS in local self lab java python npm; do
      arch=$(uname)
      b_NT=$(uname -a | grep CYGWIN | wc -l)
      if (( b_NT )); then
        arch=win
      fi
      case $ACCESS in
        self) root=$self ;;
        lab) root=$lab ;;
        java) root=$self; arch=java ;;
        npm) root=$self; arch=npm; BIT="" ;;
        python) root=$self; arch=python; BIT="" ;;
        local) root=$self; arch=local ;;
      esac
      if [[ $DIR == scripts ]]; then
        export "${ACCESS}_${DIR}"="${root}/arch/${DIR}"
      else
        export "${ACCESS}_${DIR}"="${root}/arch/${arch}${BIT}/${DIR}"
      fi
    done
  done

  export PATH=.:~$local_bin:~$self_bin:~$self_scripts:~$lab_bin:~$lab_scripts:~$python_bin:~$npm_bin:~$java_bin:$PATH
}
_starship_legacy_paths
unfunction _starship_legacy_paths

export PATH="$HOME/.local/bin:$HOME/arch/scripts:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Prefer the installed runtime. When this managed .zshrc is symlinked before
# its companion file is installed, resolve the runtime next to the source file
# so that tp and tl remain available.
_starship_runtime_file="$HOME/.config/starship-theme.zsh"
if [[ ! -f "$_starship_runtime_file" ]]; then
  _starship_runtime_file="${${(%):-%N}:A:h}/.config/starship-theme.zsh"
fi

if [[ -f "$_starship_runtime_file" ]]; then
  source "$_starship_runtime_file"
elif command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
unset _starship_runtime_file
