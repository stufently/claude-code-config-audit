# Cleanup script for Claude Code configuration and credentials (Windows).
# Removes: ~/.claude.json, ~/.claude/.credentials.json, alternative configs,
# and backup copies. Does NOT touch logs or project-level settings.

param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
$removed = 0

function Say($msg) { Write-Host $msg }

function Remove-ClaudeFile {
    param([string]$Path, [string]$Label)
    if (Test-Path -LiteralPath $Path) {
        if ($DryRun) {
            Say "[dry-run] would remove ${Label}: $Path"
        } else {
            Remove-Item -LiteralPath $Path -Force
            Say "removed ${Label}: $Path"
        }
        $script:removed++
    } else {
        Say "not found: ${Label} ($Path)"
    }
}

function Stop-ClaudeProcesses {
    Say "==> Stopping Claude Code processes..."
    # Match exact 'claude' process name
    $procs = Get-Process -Name 'claude' -ErrorAction SilentlyContinue
    if ($procs) {
        if ($DryRun) {
            Say "[dry-run] would kill $($procs.Count) Claude process(es)"
        } else {
            $procs | Stop-Process -Force -ErrorAction SilentlyContinue
            Say "stopped $($procs.Count) Claude process(es)"
        }
    } else {
        Say "no Claude Code processes found"
    }
}

function Remove-Backups {
    Say "==> Removing backup copies..."
    $backupDir = Join-Path $configDir 'backups'
    $foundBackups = 0
    if (Test-Path -LiteralPath $backupDir) {
        $backups = Get-ChildItem -Path $backupDir -Filter '.claude.json.backup.*' -Force -ErrorAction SilentlyContinue
        foreach ($b in $backups) {
            if ($DryRun) {
                Say "[dry-run] would remove backup: $($b.FullName)"
            } else {
                Remove-Item -LiteralPath $b.FullName -Force
                Say "removed backup: $($b.FullName)"
            }
            $script:removed++
            $foundBackups++
        }
    }
    if ($foundBackups -eq 0) {
        Say "no backup copies found"
    }
}

# Determine config directory
$configDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $env:USERPROFILE '.claude' }
$mainConfig = Join-Path $env:USERPROFILE '.claude.json'

Say "==> Claude Code cleanup"
Say ""

Stop-ClaudeProcesses
Say ""

Say "==> Removing configuration files..."
Remove-ClaudeFile -Path $mainConfig -Label 'main config (userID, machineID, oauthAccount)'
Remove-ClaudeFile -Path (Join-Path $configDir '.credentials.json') -Label 'credentials'
Remove-ClaudeFile -Path (Join-Path $configDir '.claude.json') -Label 'alternative config'
Remove-ClaudeFile -Path (Join-Path $configDir '.config.json') -Label 'alternative global config'

Remove-Backups

Say ""
Say "==> Cleanup complete. Removed $removed file(s)."
Say ""
Say "Next steps:"
Say "  1. Close and reopen your terminal to clear environment variables."
Say "  2. Check settings.json for any API keys or tokens:"
Say "     $(Join-Path $configDir 'settings.json')"
Say "  3. Run 'claude' to start fresh and authorize with a new account."
Say "  4. Do NOT restore the old config."

if ($DryRun) {
    Say ""
    Say "(dry-run mode — no files were actually removed)"
}
