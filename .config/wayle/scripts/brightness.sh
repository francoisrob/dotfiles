#!/bin/sh
# Monitor brightness over DDC/CI for the two desk panels.
#
# Replaces the old brightnessctl "backlight" module. brightnessctl drives an
# internal laptop panel backlight through /sys/class/backlight; this machine has
# no internal panel, only two external Dells. Both expose VCP 0x10 (Brightness,
# 0-100) over I2C, which hardware.i2c.enable in modules/system/boot.nix already
# opens to the `video` group, so no extra privileges are needed.
#
# PERFORMANCE. /bin/sh, and the `get` path takes zero forks. Measured with
# hyperfine: POSIX sh + `read` builtin 2.6ms, bash + `read` 3.3ms, bash + $(cat)
# 5.2ms, compiled Bun binary 10.4ms for the same work (a 94MB binary, 4x slower,
# because at this size it is all interpreter startup). `get` is the only
# subcommand the bar polls, so it is answered before anything else runs.
#
# ddcutil costs ~1s per call, and the cost is opening the I2C/DRM device rather
# than bus chatter, so --sleep-multiplier does not help. Hence the cache.
#
# CONCURRENCY. Locking is PER DISPLAY, not global. The panels are on separate
# buses (/dev/i2c-9 and /dev/i2c-13); a shared lock just made display 2 wait out
# display 1's ~1s call, which looked like the right monitor changing before the
# left. Contention only happens within one bus, which is what
# "flock() for /dev/i2c-9 failed on 2 calls" reports.
#
# VALIDATION. Every value is checked numeric before it reaches arithmetic. This
# is not defensive padding: a transient ddcutil read failure made panel_read
# return empty, `sync` wrote that empty string into the cache, and the next
# `down` evaluated `$(( - 5))` to -5, which clamped to 0 and blacked out both
# monitors. A bad read must leave the cache alone rather than poison it.
#
# AUTO-BRIGHTNESS. These panels have an ambient light sensor on VCP 0x66. Dell
# uses non-standard values (0x71 = on, 0x51 = off), which is why ddcutil reports
# "Invalid value" reading it: MCCS only defines 0x01 and 0x02. While the sensor
# is on it continuously overwrites brightness, so manual writes get reverted. The
# monitors also reset 0x66 back to ON across a power cycle, so `auto` reads the
# hardware rather than the cache, which would otherwise flip the toggle the wrong
# way after a reboot.

set -u

# This script must not depend on the caller's PATH. Solaar's systemd unit runs
# with a deliberately minimal one (coreutils, findutils, gnugrep, gnused,
# systemd and nothing else), so when a Solaar rule executes this script neither
# ddcutil nor flock resolves and every call silently does nothing. Both live in
# /run/current-system/sw/bin. This bit me as a false fix: it worked when run by
# hand and only failed under the service, because a manual run inherits the
# shell's PATH.
PATH="/run/current-system/sw/bin:/run/wrappers/bin:${PATH:-}"

STATE="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness"

# Hot path, first and cheapest: no function definitions, no subshells, no forks.
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
# Floor of 5 rather than 0. These panels at 0 are effectively off, which leaves
# you unable to see the screen well enough to turn them back up.
MIN=5
MAX=100
FALLBACK=50
BUSCACHE="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness.buses"
HOLDFLAG="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness.hold"
HOLDLOCK="${XDG_RUNTIME_DIR:-/tmp}/wayle-brightness.hold.lock"
# Repeat cadence while a key is held, and a smaller step than a discrete press so
# the ramp is controllable. At 0.15s x 3 a one second hold moves ~20 points and
# the full 5-100 range takes about 5s of holding. The first attempt used the
# discrete step of 5 at 0.12s, which crossed the entire range in under a second
# and was unusable.
HOLD_INTERVAL=0.15
HOLD_STEP=3
# Deadman switch: bounds the loop to ~HOLD_MAX * HOLD_INTERVAL seconds in case a
# release notification is ever missed.
HOLD_MAX=40
AUTO_ON=0x71
AUTO_OFF=0x51

# Address panels by I2C bus, not by ddcutil display number. `--display N` makes
# ddcutil re-enumerate every display on every single invocation: measured 0.896s
# per call versus 0.236s for `--bus N`, a 3.8x difference, and it was the whole
# reason a keypress took so long to show on screen. Bus numbers are stable while
# the machine is up but can change across reboots or a re-plug, so they are
# discovered once and cached in the runtime dir, which is cleared on boot.
buses() {
	if [ -s "$BUSCACHE" ]; then
		read -r b <"$BUSCACHE"
		if [ -n "$b" ]; then
			echo "$b"
			return
		fi
	fi
	b=$(ddcutil detect --brief 2>/dev/null |
		sed -n 's|.*/dev/i2c-\([0-9][0-9]*\).*|\1|p' | tr '\n' ' ')
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

# -w waits rather than failing outright; `|| true` keeps a dropped call from
# taking the script down with it.
ddc() {
	_b=$1
	shift
	flock -w 10 "$I2CLOCK.$_b" ddcutil "$@" --bus "$_b" 2>/dev/null || true
}

# Fan out across buses concurrently, then wait. Each panel is on its own bus, so
# this is real parallelism: both change together in ~0.35s rather than ~1s apart.
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
	# --brief prints: VCP 10 C <current> <max>
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
	# Cold start, or the cache was unreadable: pay the ~1s read once.
	v=$(panel_read)
	is_num "$v" || v=$FALLBACK
	echo "$v" >"$STATE"
	echo "$v"
}

# Coalescing background writer. Rapid scrolls would otherwise queue a ddcutil
# process per scroll; flock -n means a second scroll does not start another
# writer, and the running one re-reads STATE and pushes the newest value, so
# intermediate steps are skipped rather than replayed one by one.
flush() {
	(
		exec 9>"$FLUSHLOCK"
		flock -n 9 || exit 0
		# The sensor has to go for manual control to stick, but only when we
		# believe it is on: sensor_write is two ddcutil calls, and doing it
		# unconditionally put a ~2s delay in front of every scroll.
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

# step <up|down> [amount]  -- amount defaults to the discrete-press STEP; the
# held-key loop passes the smaller HOLD_STEP.
step() {
	amt=${2:-$STEP}
	cur=$(get)
	is_num "$cur" || cur=$FALLBACK
	# Clamp before apply so the arithmetic can never go negative.
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
# Held-key repeat. Diverting a key to HID++ loses auto-repeat: the keyboard sends
# one notification on press and one on release, and never the repeat stream the
# normal HID path would generate. So the repeat is driven here, from press until
# release, which is what `hold` and `release` are for.
#
# HOLD_MAX is a deadman switch. If the release notification is ever missed the
# loop would otherwise run until it hit the clamp, so it is bounded to roughly
# HOLD_MAX * HOLD_INTERVAL seconds regardless.
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
	# Reads the panel, not AUTOSTATE. This runs on a click so the ~1s read is
	# affordable, and it is the only way to stay correct after a power cycle
	# resets the sensor behind our back.
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
# Re-read the panels and rebuild the caches, for when brightness or the sensor
# changed outside this script (the monitor's own buttons, or a power cycle).
# A failed read leaves the existing cache alone rather than blanking it.
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
