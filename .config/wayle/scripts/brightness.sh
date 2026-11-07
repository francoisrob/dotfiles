#!/bin/sh

set -u

PATH="/run/current-system/sw/bin:/run/wrappers/bin:${PATH:-}"

STATE="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness"

if [ "${1:-get}" = get ] && [ -s "$STATE" ]; then
	read -r v <"$STATE"
	case $v in
	'' | *[!0-9]*) ;;
	*)
		echo "$v"
		exit 0
		;;
	esac
fi

AUTOSTATE="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness-auto"
I2CLOCK="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness.i2c"
FLUSHLOCK="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness.flush"
STEP=5
MIN=5
MAX=100
FALLBACK=50
BUSCACHE="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness.buses"
HOLDFLAG="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness.hold"
HOLDLOCK="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness.hold.lock"
HOLD_INTERVAL=0.15
HOLD_STEP=3
HOLD_MAX=40
AUTO_ON=0x71
AUTO_OFF=0x51

buses() {
	if [ -s "$BUSCACHE" ]; then
		read -r b <"$BUSCACHE"
		if [ -n "$b" ]; then
			echo "$b"
			return
		fi
	fi
	b=$(ddcutil detect --brief 2>/dev/null |
		sed -n 's|.*/dev/i2c-\([0-9][0-9]*\).*|\1|p' | sort -un | tr '\n' ' ')
	b=${b% }
	[ -n "$b" ] && echo "$b" >"$BUSCACHE"
	echo "$b"
}

is_num() {
	case ${1:-} in
	'' | *[!0-9]*) return 1 ;;
	*) return 0 ;;
	esac
}

ddc() {
	_b=$1
	shift
	flock -w 10 "$I2CLOCK.$_b" ddcutil "$@" --bus "$_b" 2>/dev/null || true
}

ddc_all() {
	for b in $(buses); do
		ddc "$b" "$@" &
	done
	wait
}

first_bus() {
	set -- $(buses)
	echo "${1:-}"
}

panel_read() {
	set -- $(ddc "$(first_bus)" getvcp 10 --brief)
	[ $# -ge 4 ] && is_num "$4" && echo "$4"
}

sensor_on() {
	case $(ddc "$(first_bus)" getvcp 66) in
	*"sl=$AUTO_ON"*) return 0 ;;
	*) return 1 ;;
	esac
}

sensor_write() {
	ddc_all setvcp 66 "$1" --noverify
}

get() {
	if [ -s "$STATE" ]; then
		read -r v <"$STATE"
		if is_num "$v"; then
			echo "$v"
			return
		fi
	fi
	v=$(panel_read)
	is_num "$v" || v=$FALLBACK
	echo "$v" >"$STATE"
	echo "$v"
}

flush() {
	(
		exec 9>"$FLUSHLOCK"
		flock -n 9 || exit 0
		if [ -s "$AUTOSTATE" ]; then read -r a <"$AUTOSTATE"; else a=on; fi
		if [ "$a" = on ]; then
			sensor_write "$AUTO_OFF"
			echo off >"$AUTOSTATE"
		fi
		last=
		while :; do
			read -r cur <"$STATE" 2>/dev/null || break
			is_num "$cur" || break
			[ "$cur" = "$last" ] && break
			last=$cur
			ddc_all setvcp 10 "$cur" --noverify
		done
	) >/dev/null 2>&1 &
}

apply() {
	is_num "${1:-}" || return 1
	v=$1
	[ "$v" -lt "$MIN" ] && v=$MIN
	[ "$v" -gt "$MAX" ] && v=$MAX
	echo "$v" >"$STATE"
	flush
	echo "$v"
}

step() {
	amt=${2:-$STEP}
	cur=$(get)
	is_num "$cur" || cur=$FALLBACK
	case $1 in
	up) next=$((cur + amt)) ;;
	down) next=$((cur - amt)) ;;
	esac
	[ "$next" -lt "$MIN" ] && next=$MIN
	apply "$next"
}

case "${1:-get}" in
get) get ;;
up) step up ;;
down) step down ;;
hold)
	dir=${2:-up}
	echo "$dir" >"$HOLDFLAG"
	(
		exec 9>"$HOLDLOCK"
		flock -n 9 || exit 0
		i=0
		while [ -f "$HOLDFLAG" ] && [ "$i" -lt "$HOLD_MAX" ]; do
			read -r d <"$HOLDFLAG" 2>/dev/null || break
			case $d in
			up | down) step "$d" "$HOLD_STEP" >/dev/null ;;
			*) break ;;
			esac
			i=$((i + 1))
			sleep "$HOLD_INTERVAL"
		done
		rm -f "$HOLDFLAG"
	) >/dev/null 2>&1 &
	get
	;;
release) rm -f "$HOLDFLAG" ;;
auto)
	if sensor_on; then
		sensor_write "$AUTO_OFF"
		echo off >"$AUTOSTATE"
	else
		sensor_write "$AUTO_ON"
		echo on >"$AUTOSTATE"
	fi
	cat "$AUTOSTATE"
	;;
auto-status)
	if [ -s "$AUTOSTATE" ]; then
		read -r a <"$AUTOSTATE"
		echo "$a"
	elif sensor_on; then
		echo on | tee "$AUTOSTATE"
	else
		echo off | tee "$AUTOSTATE"
	fi
	;;
sync)
	v=$(panel_read)
	if is_num "$v"; then echo "$v" >"$STATE"; fi
	if sensor_on; then echo on >"$AUTOSTATE"; else echo off >"$AUTOSTATE"; fi
	get
	;;
*)
	echo "usage: ${0##*/} {get|up|down|auto|auto-status|sync}" >&2
	exit 1
	;;
esac
