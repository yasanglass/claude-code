#!/bin/bash
INPUT=$(cat)

EVENT=$(echo "$INPUT" | jq -r '.hook_event_name')
CWD=$(echo "$INPUT" | jq -r '.cwd')
if [ "$CWD" = "$HOME" ]; then
  DIR_NAME="home directory"
else
  DIR_NAME=$(basename "$CWD")
fi

case "$EVENT" in
  Stop)
    STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active')
    if [ "$STOP_ACTIVE" = "false" ] || [ "$STOP_ACTIVE" = "null" ]; then
      say "Claude finished in $DIR_NAME" &
    fi
    ;;
  Notification)
    TITLE=$(echo "$INPUT" | jq -r '.title // "Claude"')
    say "$TITLE in $DIR_NAME" &
    ;;
esac

exit 0
