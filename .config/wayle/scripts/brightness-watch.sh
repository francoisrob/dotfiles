#!/bin/sh
# Emits the brightness level whenever it changes, for the wayle module running in
# `watch` mode.
#
# Why this exists. brightness.sh is driven from three places: the bar's own
# scroll, the bar's click, and the MX Keys brightness keys via a Solaar rule.
# Only the first two are things wayle knows about, so `on-action` cannot see a
# keypress at all and the bar sat on a stale number until its next poll, which is
# what made the value look like it took forever to catch up. Polling faster would
# work but burns a process every interval forever to notice a change that happens
# a few times a day.
#
# Instead this blocks on inotify against the state file and prints only when it
# actually changes, so the bar updates the moment any of the three paths writes,
# and costs nothing in between.
#
# PATH is set for the same reason as in brightness.sh: wayle's unit does not
# necessarily carry /run/current-system/sw/bin, and inotifywait lives there.

PATH="/run/current-system/sw/bin:/run/wrappers/bin:${PATH:-}"

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
STATE="$RUNTIME/wayle-brightness"
NAME="wayle-brightness"

emit() {
	if [ -s "$STATE" ]; then
		read -r v <"$STATE" 2>/dev/null || return
		case $v in
		'' | *[!0-9]*) return ;;
		*) echo "$v" ;;
		esac
	fi
}

# Seed the bar immediately rather than leaving it blank until the first change.
# Falls back to brightness.sh so a cold cache still resolves to a real value.
if [ -s "$STATE" ]; then
	emit
else
	"$(dirname "$0")/brightness.sh" get
fi

# Watch the directory, not the file: the state file gets replaced rather than
# appended, and an inotify watch on the inode would be lost on the first write.
last=
inotifywait -q -m -e close_write,moved_to --format '%f' "$RUNTIME" 2>/dev/null |
	while read -r f; do
		[ "$f" = "$NAME" ] || continue
		cur=$(emit)
		[ -n "$cur" ] || continue
		[ "$cur" = "$last" ] && continue
		last=$cur
		echo "$cur"
	done
