#!/bin/sh

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

publish

inotifywait -q -m -e close_write,moved_to --format '%f' "$RUNTIME" 2>/dev/null |
	while read -r f; do
		case $f in
		"$NAME" | "$AUTONAME") publish ;;
		*) continue ;;
		esac
	done
