# Инструменты для очистки профиля Claude Code

Скрипты для полного удаления конфигурации и учётных данных Claude Code перед использованием другого аккаунта.

## Что удаляют скрипты

- `~/.claude.json` — основной конфиг (userID, machineID, oauthAccount)
- `~/.claude/.credentials.json` — токены доступа и обновления
- `~/.claude/.claude.json` — альтернативный конфиг (если существует)
- `~/.claude/.config.json` — альтернативный глобальный конфиг (если существует)
- `~/.claude/backups/.claude.json.backup.*` — резервные копии конфига

Скрипты также завершают все процессы Claude Code перед удалением файлов.

## Что скрипты НЕ делают

- Не удаляют логи
- Не изменяют `settings.json` — API-ключи нужно удалить вручную
- Не удаляют проектные настройки из `.claude/` в каталогах проектов
- Не очищают переменные окружения — откройте новый терминал после запуска

## Использование

### Linux и macOS

```bash
git clone https://github.com/stufently/claude-code-config-audit.git "$HOME/claude-code-config-audit"
bash "$HOME/claude-code-config-audit/cleanup.sh"
```

Или одной командой:

```bash
curl -fsSL https://raw.githubusercontent.com/stufently/claude-code-config-audit/main/cleanup.sh | bash
```

Для проверки без удаления:

```bash
bash "$HOME/claude-code-config-audit/cleanup.sh" --dry-run
```

### Windows (PowerShell)

```powershell
git clone https://github.com/stufently/claude-code-config-audit.git "$HOME\claude-code-config-audit"
& "$HOME\claude-code-config-audit\cleanup.ps1"
```

Или одной командой:

```powershell
irm https://raw.githubusercontent.com/stufently/claude-code-config-audit/main/cleanup.ps1 | iex
```

Для проверки без удаления:

```powershell
& "$HOME\claude-code-config-audit\cleanup.ps1" -DryRun
```

## После очистки

1. Откройте новый терминал для сброса переменных окружения.
2. Проверьте `settings.json` и удалите API-ключи вручную, если они там были.
3. Запустите `claude` и авторизуйтесь в новом аккаунте.
4. Не восстанавливайте старый конфиг.

## Аудит прав файлов (Linux)

Для проверки прав файла учётных данных в Linux:

```bash
bash "$HOME/claude-code-config-audit/audit.sh"
```

[Статья с описанием](article.md)
