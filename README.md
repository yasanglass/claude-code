# Claude Code Setup

My Claude Code configuration files.

## Status Line

Copy `statusline-command.sh` to `~/.claude/` and add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

Note: Requires `jq`.

## Hooks

Copy `hooks/notify-say.sh` to `~/.claude/hooks/` and add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify-say.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify-say.sh"
          }
        ]
      }
    ]
  }
}
```

Note: The notification hook uses macOS `say` for text-to-speech.
