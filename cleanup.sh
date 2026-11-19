#!/usr/bin/env bash
# Cleanup script for Claude Code configuration and credentials.
# Removes: ~/.claude.json, ~/.claude/.credentials.json, alternative configs,
# and backup copies. Does NOT touch logs or project-level settings.
set -eu

DRY_RUN=0
if (( $# == 1 )); then
  case "${1:-}" in
    -h|--help) echo 'Usage: bash cleanup.sh [--dry-run]'; exit 0 ;;
    --dry-run) DRY_RUN=1 ;;
    *) echo 'Unsupported argument. Use --help.' >&2; exit 2 ;;
  esac
elif (( $# )); then
  echo 'Unsupported arguments. Use --help.' >&2; exit 2
fi

config_dir=${CLAUDE_CONFIG_DIR:-"${HOME:?}/.claude"}
removed=0

say() { printf '%s\n' "$*"; }

remove_file() {
  local file=$1 label=$2
  if [[ -L $file || -e $file ]]; then
    if (( DRY_RUN )); then
      say "[dry-run] would remove $label: $file"
    else
      rm -f -- "$file"
      say "removed $label: $file"
    fi
    (( ++removed )) || true
  else
    say "not found: $label ($file)"
  fi
}

kill_processes() {
  say "==> Stopping Claude Code processes..."
  local pids=()
  if command -v pgrep >/dev/null 2>&1; then
    # Match exact 'claude' binary name
    while IFS= read -r pid; do
      [[ -n $pid ]] && pids+=("$pid")
    done < <(pgrep -x 'claude' 2>/dev/null || true)
  fi
  if (( ${#pids[@]} > 0 )); then
    if (( DRY_RUN )); then
      say "[dry-run] would kill ${#pids[@]} Claude process(es): ${pids[*]}"
    else
      kill "${pids[@]}" 2>/dev/null || true
      sleep 1
      for pid in "${pids[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
          kill -9 "$pid" 2>/dev/null || true
        fi
      done
      say "stopped ${#pids[@]} Claude process(es)"
    fi
  else
    say "no Claude Code processes found"
  fi
}

remove_backups() {
  say "==> Removing backup copies..."
  local found_backups=0
  if [[ -d "${config_dir}/backups" ]]; then
    for backup in "${config_dir}"/backups/.claude.json.backup.*; do
      if [[ -e $backup ]]; then
        if (( DRY_RUN )); then
          say "[dry-run] would remove backup: $backup"
        else
          rm -f -- "$backup"
          say "removed backup: $backup"
        fi
        (( ++removed )) || true
        (( ++found_backups )) || true
      fi
    done
  fi
  if (( found_backups == 0 )); then
    say "no backup copies found"
  fi
}

say "==> Claude Code cleanup"
say ""

kill_processes
say ""

say "==> Removing configuration files..."
remove_file "${HOME}/.claude.json" "main config (userID, machineID, oauthAccount)"
remove_file "${config_dir}/.credentials.json" "credentials"
remove_file "${config_dir}/.claude.json" "alternative config"
remove_file "${config_dir}/.config.json" "alternative global config"

remove_backups

say ""
say "==> Cleanup complete. Removed $removed file(s)."
say ""
say "Next steps:"
say "  1. Open a new terminal to clear environment variables."
say "  2. Check settings.json for any API keys or tokens:"
say "     ${config_dir}/settings.json"
say "  3. Run 'claude' to start fresh and authorize with a new account."
say "  4. Do NOT restore the old config."

if (( DRY_RUN )); then
  say ""
  say "(dry-run mode — no files were actually removed)"
fi
