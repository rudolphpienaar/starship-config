#!/bin/sh
# Managed by this repository.
# Print compact system values for Starship's status pills.

human_bytes() {
  awk -v bytes="$1" 'BEGIN {
    split("B KiB MiB GiB TiB", units, " ")
    unit = 1
    while (bytes >= 1024 && unit < 5) {
      bytes /= 1024
      unit++
    }
    if (unit == 1) printf "%d%s\n", bytes, units[unit]
    else if (bytes >= 10) printf "%.0f%s\n", bytes, units[unit]
    else printf "%.1f%s\n", bytes, units[unit]
  }'
}

ram_values() {
  if [ -r /proc/meminfo ]; then
    awk '
      /^MemTotal:/ { total = $2 }
      /^MemAvailable:/ { available = $2 }
      END {
        if (available && total) printf "%.0f %.0f\n", available * 1024, total * 1024
        else exit 1
      }
    ' /proc/meminfo
    return
  fi

  if command -v vm_stat >/dev/null 2>&1 && command -v sysctl >/dev/null 2>&1; then
    total_bytes=$(sysctl -n hw.memsize 2>/dev/null) || return 1
    available_bytes=$(vm_stat | awk '
      NR == 1 {
        page_size = $8
        gsub(/[^0-9]/, "", page_size)
      }
      /^Pages (free|inactive|speculative):/ {
        pages = $NF
        gsub(/[^0-9]/, "", pages)
        available += pages
      }
      END {
        if (page_size && available) printf "%.0f\n", page_size * available
        else exit 1
      }
    ') || return 1
    printf '%s %s\n' "$available_bytes" "$total_bytes"
    return 0
  fi

  return 1
}

free_disk_value() {
  # POSIX df reports capacity as an integer percentage in its fifth column.
  used_percent=$(df -Pk . 2>/dev/null | awk 'NR == 2 { gsub(/%/, "", $5); print $5 }')
  case $used_percent in
    ''|*[!0-9]*) return 1 ;;
  esac
  printf '%s\n' "$((100 - used_percent))"
}

load_value() {
  if [ -r /proc/loadavg ]; then
    awk '{ print $1; exit }' /proc/loadavg
    return
  fi

  if command -v sysctl >/dev/null 2>&1; then
    sysctl -n vm.loadavg 2>/dev/null | awk '{ gsub(/[{}]/, ""); print $1; exit }'
    return
  fi

  return 1
}

matches_state() {
  value=$1
  metric=$2
  state=$3
  awk -v value="$value" -v metric="$metric" -v state="$state" 'BEGIN {
    if (metric == "load") {
      if (state == "red") exit !(value > 10)
      if (state == "yellow") exit !(value > 5 && value <= 10)
      exit !(value <= 5)
    }
    if (state == "red") exit !(value < 5)
    if (state == "yellow") exit !(value >= 5 && value < 15)
    exit !(value >= 15)
  }'
}

case ${1:-} in
  ram)
    values=$(ram_values) || exit 1
    set -- $values
    printf '%s/%s\n' "$(human_bytes "$1")" "$(human_bytes "$2")"
    ;;
  ram-state)
    requested_state=${2:-}
    values=$(ram_values) || exit 1
    set -- $values
    ram_percent=$(awk -v available="$1" -v total="$2" 'BEGIN { print available * 100 / total }')
    matches_state "$ram_percent" ram "$requested_state"
    ;;
  disk)
    disk_percent=$(free_disk_value) || exit 1
    printf '%s\n' "$disk_percent"
    ;;
  disk-state)
    disk_percent=$(free_disk_value) || exit 1
    matches_state "$disk_percent" disk "${2:-}"
    ;;
  load) load_value ;;
  load-state)
    load_average=$(load_value) || exit 1
    matches_state "$load_average" load "${2:-}"
    ;;
  *) exit 2 ;;
esac
