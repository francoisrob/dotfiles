#!/usr/bin/env bash
# Shows a rofi list of running claude sessions with their project and state.

pids=$(pgrep -x claude 2>/dev/null)

if [ -z "$pids" ]; then
    notify-send "Claude Code" "No active sessions"
    exit 0
fi

entries=""
for pid in $pids; do
    [ ! -d "/proc/$pid" ] && continue

    cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || echo "unknown")
    project=$(basename "$cwd")

    stat_file="/proc/$pid/stat"
    if [ -f "$stat_file" ]; then
        state_char=$(awk '{print $3}' "$stat_file")
    else
        state_char="?"
    fi

    case "$state_char" in
        R) state="⚡ working" ;;
        S|D) state="⏳ waiting" ;;
        T) state="⏸ stopped" ;;
        Z) state="💀 zombie" ;;
        *) state="? unknown" ;;
    esac

    entries="$entries$project — $state (pid $pid)\n"
done

printf "$entries" | rofi -dmenu -p "Claude sessions" -i
