#!/usr/bin/env bash
# Usage: test.sh <scratch-clean binary>. Runs in the nix build sandbox (non-root) or by hand.
set -u

bin=${1:?usage: test.sh <scratch-clean binary>}
work=$(mktemp -d)
cleanup() {
  chmod -R u+rwx "$work" 2>/dev/null
  rm -rf "$work"
}
trap cleanup EXIT

fail=0
pass=0
check() {
  if "$@"; then pass=$((pass + 1)); else echo "FAIL: ${*}" >&2; fail=$((fail + 1)); fi
}
exists() { [ -e "$1" ]; }
gone() { [ ! -e "$1" ]; }
contains() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

old="2020-01-01"
age() { touch -d "$old" "$1"; }
make_old() { mkdir -p "$1" && touch -d "$old" "$1/f" && age "$1"; }
make_new() { mkdir -p "$1" && touch "$1/f"; }

fresh_home() {
  home=$work/home.$1
  scratch=$home/hub/scratch
  mkdir -p "$scratch/claude-tmp" "$scratch/tmp"
}

run() {
  out=$(HOME=$home "$bin" "$@" 2>"$work/err")
  code=$?
  err=$(cat "$work/err")
}

# dry run removes nothing and exits 0
fresh_home dry
make_old "$scratch/olddir"
run
check exists "$scratch/olddir"
check [ "$code" -eq 0 ]
check contains "$out" "would remove $scratch/olddir"

# --delete removes only old entries, at every level
fresh_home del
make_old "$scratch/olddir"
make_new "$scratch/newdir"
touch -d "$old" "$scratch/oldfile"
make_old "$scratch/claude-tmp/proj/session/abc"
mkdir -p "$scratch/claude-tmp/proj/session"
make_new "$scratch/claude-tmp/proj/session/fresh"
make_old "$scratch/tmp/oldtmp"
make_new "$scratch/tmp/newtmp"
run --delete
check [ "$code" -eq 0 ]
check gone "$scratch/olddir"
check gone "$scratch/oldfile"
check exists "$scratch/newdir"
check gone "$scratch/claude-tmp/proj/session/abc"
check exists "$scratch/claude-tmp/proj/session/fresh"
check gone "$scratch/tmp/oldtmp"
check exists "$scratch/tmp/newtmp"
check exists "$scratch/claude-tmp"
check exists "$scratch/tmp"

# one old file keeps a directory whose directory mtime is old
fresh_home mixed
mkdir -p "$scratch/mixed"
touch "$scratch/mixed/recent"
age "$scratch/mixed"
run --delete
check exists "$scratch/mixed/recent"

# tracked files and the two roots are never entries
fresh_home tracked
touch -d "$old" "$scratch/README.md" "$scratch/.gitkeep"
age "$scratch/tmp"
age "$scratch/claude-tmp"
run --delete
check exists "$scratch/README.md"
check exists "$scratch/.gitkeep"
check exists "$scratch/tmp"
check exists "$scratch/claude-tmp"
check [ "$code" -eq 0 ]

# names with spaces and newlines
fresh_home names
make_old "$scratch/with space"
make_old "$scratch/$(printf 'line\nbreak')"
run --delete
check gone "$scratch/with space"
check [ "$(find "$scratch" -mindepth 1 -maxdepth 1 | wc -l)" -eq 2 ]

# missing claude-tmp and tmp are fine
fresh_home bare
rmdir "$scratch/claude-tmp" "$scratch/tmp"
make_old "$scratch/olddir"
run --delete
check [ "$code" -eq 0 ]
check gone "$scratch/olddir"

# a symlink is removed itself and its target is left alone
fresh_home link
make_old "$work/target"
ln -s "$work/target" "$scratch/link"
touch -h -d "$old" "$scratch/link"
run --delete
check gone "$scratch/link"
check exists "$work/target/f"

# bad argument
fresh_home arg
run --bogus
check [ "$code" -eq 2 ]

if [ "$(id -u)" -ne 0 ]; then
  # an entry that cannot be removed does not stop later entries, and the exit code reports it
  fresh_home stuck
  make_old "$scratch/a-stuck"
  mkdir "$scratch/a-stuck/sub"
  touch -d "$old" "$scratch/a-stuck/sub/f"
  touch -d "$old" "$scratch/a-stuck/sub"
  age "$scratch/a-stuck"
  chmod 555 "$scratch/a-stuck/sub"
  make_old "$scratch/z-later"
  make_old "$scratch/tmp/also-later"
  run --delete
  chmod -R u+rwx "$scratch/a-stuck"
  check [ "$code" -ne 0 ]
  check gone "$scratch/z-later"
  check gone "$scratch/tmp/also-later"
  check contains "$err" "failed to remove $scratch/a-stuck"

  # a subfolder that cannot be read keeps the entry (age unknown), later entries still run
  fresh_home unreadable
  make_old "$scratch/a-locked"
  mkdir "$scratch/a-locked/sub"
  touch -d "$old" "$scratch/a-locked/sub/f"
  touch -d "$old" "$scratch/a-locked/sub"
  age "$scratch/a-locked"
  chmod 000 "$scratch/a-locked/sub"
  make_old "$scratch/z-later"
  run --delete
  chmod -R u+rwx "$scratch/a-locked"
  check [ "$code" -ne 0 ]
  check exists "$scratch/a-locked"
  check gone "$scratch/z-later"
  check contains "$err" "kept $scratch/a-locked"

  # an unreadable subfolder does not hide a recent file elsewhere in the entry
  fresh_home unreadable_recent
  mkdir -p "$scratch/b/locked" "$scratch/b/ok"
  touch -d "$old" "$scratch/b/locked/f"
  touch "$scratch/b/ok/new"
  chmod 000 "$scratch/b/locked"
  run --delete
  chmod -R u+rwx "$scratch/b"
  check exists "$scratch/b/ok/new"

  # dry run reports the unreadable entry too and removes nothing
  fresh_home unreadable_dry
  make_old "$scratch/c-locked"
  mkdir "$scratch/c-locked/sub"
  touch -d "$old" "$scratch/c-locked/sub/f" "$scratch/c-locked/sub"
  age "$scratch/c-locked"
  chmod 000 "$scratch/c-locked/sub"
  run
  chmod -R u+rwx "$scratch/c-locked"
  check [ "$code" -ne 0 ]
  check exists "$scratch/c-locked/sub/f"
fi

echo "scratch-clean tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
