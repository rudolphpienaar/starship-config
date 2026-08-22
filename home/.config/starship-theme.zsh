# Managed by this repository.
# Shared Starship runtime used by ordinary installs and Home Manager.

export STARSHIP_PILLS=${STARSHIP_PILLS:-"on"}
export STARSHIP_LAYOUT=${STARSHIP_LAYOUT:-"2line"}

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
