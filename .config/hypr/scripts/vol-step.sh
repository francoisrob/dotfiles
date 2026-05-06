#!/usr/bin/env sh
# Step DEFAULT_AUDIO_SINK volume to the next/previous multiple of 5 (0..100).
dir="$1"
cur=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2*100 + 0.5)}')
case "$dir" in
    up)
        new=$(( cur / 5 * 5 + 5 ))
        [ "$new" -gt 100 ] && new=100
        ;;
    down)
        new=$(( (cur + 4) / 5 * 5 - 5 ))
        [ "$new" -lt 0 ] && new=0
        ;;
    *)
        echo "usage: $0 up|down" >&2
        exit 1
        ;;
esac
wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ "${new}%"
