#!/usr/bin/env bash
# Local metadata only. Labels are constant so paths never enter the report.
set -eu

if (( $# == 1 )); then
case "${1:-}" in
  -h|--help) echo 'Usage: bash audit.sh (Linux, GNU stat)'; exit 0 ;;
esac
fi
if (( $# )); then echo 'Unsupported argument. Use --help.' >&2; exit 2; fi
if [[ $(uname -s) != Linux ]] || ! stat -c %a -- / >/dev/null 2>&1; then
  echo 'Linux with GNU-compatible stat required.' >&2
  exit 2
fi

config_dir=${CLAUDE_CONFIG_DIR:-"${HOME:?}/.claude"}
status=0
searchable_parent() {
  local directory=$1
  while [[ ! -d $directory ]]; do
    if [[ -e $directory || -L $directory ]]; then return 1; fi
    directory=$(dirname -- "$directory")
  done
  [[ -x $directory ]]
}
check_file() {
  local label=$1 file=$2 parent mode
  parent=$(dirname -- "$file")
  if [[ -L $file ]]; then
    printf '%s: symlink (skipped)\n' "$label"
    status=1
  elif ! searchable_parent "$parent"; then
    printf '%s: parent inaccessible\n' "$label"
    status=1
  elif [[ -f $file ]]; then
    if ! mode=$(stat -c %a -- "$file" 2>/dev/null); then
      printf '%s: stat failed\n' "$label"
      status=1
      return
    fi
    printf '%s: present, mode %s' "$label" "$mode"
    if [[ $label == credentials && $mode != 600 ]]; then
      printf ' (expected 600)'
      status=1
    fi
    printf '\n'
  elif [[ -e $file ]]; then
    printf '%s: unexpected file type\n' "$label"
    status=1
  else
    printf '%s: not found\n' "$label"
  fi
}
check_file user-settings "$config_dir/settings.json"
check_file credentials "$config_dir/.credentials.json"
if [[ "$PWD/.claude" -ef "$config_dir" || "$PWD/.claude" == "$config_dir" ]]; then
  echo "project-settings: skipped (same config directory)"
  echo "project-local-settings: skipped (same config directory)"
  exit "$status"
fi
check_file project-settings "$PWD/.claude/settings.json"
check_file project-local-settings "$PWD/.claude/settings.local.json"
exit "$status"
