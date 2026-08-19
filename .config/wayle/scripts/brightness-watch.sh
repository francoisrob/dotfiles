#!/bin/sh
# Emits the brightness level whenever it changes, for the wayle module running in
# `watch` mode.
#
# Why this exists. brightness.sh is driven from four places: the bar's own
# scroll, the bar's click, the Hyprland XF86MonBrightness binds, and the MX Keys
# brightness keys via a Solaar rule. Only the first two are things wayle knows
# about, so `on-action` cannot see a keypress at all and the bar sat on a stale
# number until its next poll, which is what made the value look like it took
# forever to catch up. Polling faster would work but burns a process every
# interval forever to notice a change that happens a few times a day.
#
# Instead this blocks on inotify against the state files and prints only when
# something actually changes, so the bar updates the moment any of the four
# paths writes, and costs nothing in between.
#
# OUTPUT IS JSON, not a bare number: {"percentage": N, "alt": "auto"|"manual"}.
# The `alt` field is what makes the auto-brightness toggle visible. Without it
# the button was unfalsifiable from the user's side: it flipped VCP 0x66 on both
# panels for real, but the icon was static and the percentage does not move when
# the sensor takes over, so both states of the toggle looked identical and the
# button read as dead. config.toml maps alt -> icon via icon-map.
#
# PATH is set for the same reason as in brightness.sh: wayle's unit does not
# necessarily carry /run/current-system/sw/bin, and inotifywait lives there.

PATH="/run/current-system/sw/bin:/run/wrappers/bin:${PATH:-}"

RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
STATE="$RUNTIME/wayle-brightness"
AUTOSTATE="$RUNTIME/wayle-brightness-auto"
NAME="wayle-brightness"
AUTONAME="wayle-brightness-auto"
DIR=$(dirname "$0")

level() {
	if [ -s "$STATE" ]; then
		read -r v <"$STATE" 2>/dev/null || return 1
		case $v in
		'' | *[!0-9]*) return 1 ;;
		*)
			echo "$v"
			return 0
			;;
		esac
	fi
	return 1
}

# Falls back to brightness.sh, which pays the ~1s ddcutil read once, so a cold
# cache still resolves to a real value rather than blanking the module.
alt() {
	if [ -s "$AUTOSTATE" ]; then
		read -r a <"$AUTOSTATE" 2>/dev/null || a=
	else
		a=$("$DIR/brightness.sh" auto-status 2>/dev/null)
	fi
	case $a in
	on) echo auto ;;
	*) echo manual ;;
	esac
}

last=
publish() {
	v=$(level) || v=$("$DIR/brightness.sh" get 2>/dev/null)
	case $v in
	'' | *[!0-9]*) return ;;
	esac
	line="{\"percentage\": $v, \"alt\": \"$(alt)\"}"
	[ "$line" = "$last" ] && return
	last=$line
	echo "$line"
}

# Seed the bar immediately rather than leaving it blank until the first change.
publish

# Watch the directory, not the files: they get replaced rather than appended,
# and an inotify watch on the inode would be lost on the first write. Both the
# level and the auto flag are watched, so toggling the sensor repaints the icon
# without waiting for a brightness change that may never come.
inotifywait -q -m -e close_write,moved_to --format '%f' "$RUNTIME" 2>/dev/null |
	while read -r f; do
		case $f in
		"$NAME" | "$AUTONAME") publish ;;
		*) continue ;;
		esac
	done
