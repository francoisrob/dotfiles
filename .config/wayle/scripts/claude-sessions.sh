#!/usr/bin/env bash
# Finds running claude processes and reports their state for the wayle bar module.
# State heuristic: if the process has consumed CPU in the last sample it's "working",
# otherwise it's "waiting". A pid whose wchan is "wait_woken" or similar is sleeping.

pids=$(pgrep -x claude 2>/dev/null)

if [ -z "$pids" ]; then
    echo '{"text": "0", "tooltip": "No active Claude sessions", "alt": "none"}'
    exit 0
fi

count=0
working=0
lines=""

for pid in $pids; do
    [ ! -d "/proc/$pid" ] && continue

    cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || echo "unknown")
    project=$(basename "$cwd")

    # Read CPU stat to determine if working or waiting
    stat_file="/proc/$pid/stat"
    if [ -f "$stat_file" ]; then
        state_char=$(awk '{print $3}' "$stat_file")
    else
        state_char="?"
    fi

    case "$state_char" in
        R) state="working" ;;
        S|D) state="waiting" ;;
        T) state="stopped" ;;
        Z) state="zombie" ;;
        *) state="unknown" ;;
    esac

    [ "$state" = "working" ] && working=$((working + 1))
    count=$((count + 1))
    lines="$lines\n$project ($state)"
done

if [ $count -eq 0 ]; then
    echo '{"text": "0", "tooltip": "No active Claude sessions", "alt": "none"}'
    exit 0
fi

tooltip=$(printf "$lines" | sed 's/^\\n//' | tr '\n' '|' | sed 's/|/\\n/g')

if [ $working -gt 0 ]; then
    alt="working"
else
    alt="waiting"
fi

echo "{\"text\": \"$count\", \"tooltip\": \"Claude sessions:\\n$tooltip\", \"alt\": \"$alt\"}"
