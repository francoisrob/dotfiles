"""Push memory kills, agent relaunches and service crashes from the systemd journal to ntfy.

earlyoom runs without network access, so it cannot report its own kills.
Every kill (earlyoom, the kernel, systemd-oomd), every agent-revive outcome and
every unit crash, restart or stop is a structured journal entry, so this follows
the journal instead and sends one phone notification per burst of events.
"""

import argparse
import json
import os
import select
import subprocess
import sys
import time
import urllib.error
import urllib.request
from collections import deque
from dataclasses import dataclass

from oomkill import JOURNAL_FILTERS as KILL_FILTERS
from oomkill import message_text, parse_kill

MSG_UNIT_OOM = "fe6faa94e7774663a0da52717891d8ef"
MSG_OOMD_KILL = "d989611b15e44c9dbf31e3c81256e4ed"
MSG_UNIT_FAILED = "d9b373ed55a64feb8242e02dbe79a49c"
MSG_UNIT_RESTART = "5eb03494b6584870a536b337290809b3"
MSG_UNIT_STOPPED = "9d1aaa27d60140bd96365438aad20286"

# Results that mean something was killed or crashed, worth a ping for any unit.
CRASH_RESULTS = {"oom-kill", "signal", "core-dump", "watchdog"}

# agent-revive reports its outcomes to the journal under this name; notice (5) and worse are sent.
REVIVE_IDENTIFIER = "agent-revive"
REVIVE_MAX_PRIORITY = 5

MAX_LINES = 20

# Seconds between retries of a failed send (doubling), and unsent events kept while ntfy is down.
RETRY_MIN = 2.0
RETRY_MAX = 60.0
MAX_PENDING = 1000
MAX_LINE_CHARS = 300


@dataclass(frozen=True)
class Event:
    title: str
    body: str
    priority: int
    tag: str


def journal_filters():
    """Journal matches for every entry classify() can act on.

    Same-field matches are OR-ed and '+' separates OR-ed groups.
    """
    ids = [MSG_UNIT_OOM, MSG_OOMD_KILL, MSG_UNIT_FAILED, MSG_UNIT_RESTART, MSG_UNIT_STOPPED]
    return [f"MESSAGE_ID={i}" for i in ids] + ["+", f"SYSLOG_IDENTIFIER={REVIVE_IDENTIFIER}", "+"] + KILL_FILTERS


def _clip(text, limit=MAX_LINE_CHARS):
    text = " ".join(str(text).split())
    return text if len(text) <= limit else text[: limit - 1] + "…"


def _unit(entry):
    """Return the unit an entry is about, marked when it is a user unit."""
    if entry.get("USER_UNIT"):
        return f"{entry['USER_UNIT']} (user)"
    return entry.get("UNIT", "")


def _kill_event(kill):
    if kill.source == "earlyoom":
        body = f"{kill.signal} pid {kill.pid} uid {kill.uid}, {kill.rss_mib} MiB, oom_score {kill.score}"
        if kill.cmdline:
            body += f"\n{_clip(kill.cmdline)}"
        return Event(f"earlyoom killed {kill.name}", body, 4, "warning")
    where = "cgroup limit" if kill.cgroup_limit else "system out of memory"
    return Event(f"kernel killed {kill.name}", f"pid {kill.pid}, {kill.rss_mib} MiB, {where}", 5, "rotating_light")


def _revive_event(entry, message):
    try:
        level = int(entry.get("PRIORITY", 6))
    except ValueError:
        level = 6
    if level > REVIVE_MAX_PRIORITY:
        return None
    title, _, body = message.partition("\n")
    if level <= 3:
        return Event(_clip(title), _clip(body) if body else "", 4, "x")
    return Event(_clip(title), _clip(body) if body else "", 3, "recycle")


def classify(entry, watched):
    """Turn one journal entry into an Event, or None when it is not news."""
    kill = parse_kill(entry)
    if kill:
        return _kill_event(kill)
    if entry.get("SYSLOG_IDENTIFIER") == "earlyoom" or entry.get("_TRANSPORT") == "kernel":
        return None
    message = message_text(entry)
    if entry.get("SYSLOG_IDENTIFIER") == REVIVE_IDENTIFIER:
        return _revive_event(entry, message)

    message_id = entry.get("MESSAGE_ID", "")
    unit = _unit(entry)
    bare_unit = entry.get("USER_UNIT") or entry.get("UNIT", "")
    if not unit:
        return None

    if message_id == MSG_OOMD_KILL:
        return Event(f"systemd-oomd killed {unit}", _clip(message), 5, "rotating_light")
    if message_id == MSG_UNIT_OOM:
        return Event(f"OOM kill inside {unit}", _clip(message), 4, "warning")
    if message_id == MSG_UNIT_FAILED:
        result = entry.get("UNIT_RESULT", "")
        if result in CRASH_RESULTS or bare_unit in watched:
            return Event(f"{unit} failed ({result or 'unknown'})", _clip(message), 4, "x")
        return None
    if message_id == MSG_UNIT_RESTART and bare_unit in watched:
        count = entry.get("N_RESTARTS", "?")
        return Event(f"{unit} restarting (restart {count})", _clip(message), 3, "arrows_counterclockwise")
    if message_id == MSG_UNIT_STOPPED and bare_unit in watched:
        # A stop or restart someone asked for (systemctl, a deploy, shutdown), not a crash.
        job = entry.get("JOB_TYPE") or "stop"
        verb = "restarted" if job == "restart" else "stopped"
        return Event(f"{unit} {verb}", _clip(message), 3, "information_source")
    return None


def summarize(events, host):
    """Fold a burst of events into one notification payload (title, body, priority, tags)."""
    if len(events) == 1:
        e = events[0]
        return f"{host}: {e.title}", e.body, e.priority, [e.tag]
    lines = [f"• {e.title}: {e.body.splitlines()[0]}" for e in events[:MAX_LINES]]
    if len(events) > MAX_LINES:
        lines.append(f"… and {len(events) - MAX_LINES} more")
    priority = max(e.priority for e in events)
    tags = sorted({e.tag for e in events})
    return f"{host}: {len(events)} kill/crash events", "\n".join(lines), priority, tags


def journalctl_command(journalctl, cursor):
    cmd = [journalctl, "--follow", "--output=json", "--merge"]
    cmd += [f"--after-cursor={cursor}"] if cursor else ["--lines=0"]
    return cmd + journal_filters()


def read_cursor(path):
    try:
        with open(path, encoding="utf-8") as fh:
            return fh.read().strip() or None
    except FileNotFoundError:
        return None


def write_cursor(path, cursor):
    tmp = f"{path}.tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        fh.write(cursor)
    os.replace(tmp, path)


class Notifier:
    """Posts one notification to ntfy. One attempt per call: the caller decides when to retry."""

    def __init__(self, url, topic, token, opener=urllib.request.urlopen):
        self.url = url
        self.topic = topic
        self.token = token
        self.opener = opener

    def send(self, title, body, priority, tags):
        payload = json.dumps(
            {"topic": self.topic, "title": title, "message": body, "priority": priority, "tags": tags}
        ).encode()
        request = urllib.request.Request(
            self.url,
            data=payload,
            method="POST",
            headers={"Authorization": f"Bearer {self.token}", "Content-Type": "application/json"},
        )
        try:
            with self.opener(request, timeout=10) as response:
                if 200 <= response.status < 300:
                    return True
                reason = f"HTTP {response.status}"
        except (urllib.error.URLError, OSError) as err:
            reason = str(err)
        print(f"ntfy send failed: {reason}: {title}", file=sys.stderr, flush=True)
        return False


class Batcher:
    """Collects events from journal lines and sends them as one notification per burst.

    An event leaves the queue only once ntfy accepted it. A failed send is retried with a growing
    delay while newer events keep queuing. The saved cursor never moves past the oldest unsent
    event, so a restart replays everything that was not delivered.
    """

    def __init__(self, args, notifier, cursor, clock=time.monotonic):
        self.args = args
        self.notifier = notifier
        self.clock = clock
        self.cursor = cursor
        self.written = cursor
        self.pending = deque()
        self.first_at = None
        self.retry_at = 0.0
        self.retry_delay = RETRY_MIN

    def feed(self, line):
        if not line.strip():
            return
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            print(f"skipped unreadable journal line: {_clip(line)}", file=sys.stderr, flush=True)
            return
        event = classify(entry, self.args.watched)
        if event:
            self.pending.append((self.cursor, event))
            if self.first_at is None:
                self.first_at = self.clock()
            if len(self.pending) > MAX_PENDING:
                self.pending.popleft()
                print("ntfy unreachable: dropped the oldest unsent event", file=sys.stderr, flush=True)
        self.cursor = entry.get("__CURSOR", self.cursor)

    def safe_cursor(self):
        """The journal position up to which every event was sent."""
        return self.pending[0][0] if self.pending else self.cursor

    def tick(self):
        now = self.clock()
        if self.pending and now - self.first_at >= self.args.window and now >= self.retry_at:
            events = [event for _, event in self.pending]
            if self.notifier.send(*summarize(events, self.args.host)):
                self.pending.clear()
                self.first_at = None
                self.retry_delay = RETRY_MIN
            else:
                self.retry_at = now + self.retry_delay
                self.retry_delay = min(self.retry_delay * 2, RETRY_MAX)
        cursor = self.safe_cursor()
        if cursor and cursor != self.written:
            write_cursor(self.args.cursor_file, cursor)
            self.written = cursor


def run(args, notifier):
    cursor = read_cursor(args.cursor_file)
    proc = subprocess.Popen(journalctl_command(args.journalctl, cursor), stdout=subprocess.PIPE)
    fd = proc.stdout.fileno()
    batcher = Batcher(args, notifier, cursor)
    buffer = b""
    while True:
        ready, _, _ = select.select([fd], [], [], 1.0)
        if ready:
            chunk = os.read(fd, 65536)
            if not chunk:
                proc.wait()
                raise SystemExit(f"journalctl exited with {proc.returncode}")
            buffer += chunk
            *lines, buffer = buffer.split(b"\n")
            for line in lines:
                batcher.feed(line.decode("utf-8", errors="replace"))
        batcher.tick()


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--journalctl", default="journalctl")
    parser.add_argument("--url", required=True, help="ntfy base URL, e.g. http://127.0.0.1:2586")
    parser.add_argument("--topic", required=True)
    parser.add_argument("--token-file", required=True)
    parser.add_argument("--cursor-file", required=True)
    parser.add_argument("--host", default=os.uname().nodename)
    parser.add_argument("--window", type=float, default=15, help="seconds to gather a burst into one message")
    parser.add_argument("--watch", dest="watched", action="append", default=[], help="unit to report restarts and any failure for")
    args = parser.parse_args(argv)
    args.watched = set(args.watched)
    with open(args.token_file, encoding="utf-8") as fh:
        token = fh.read().strip()
    run(args, Notifier(args.url, args.topic, token))


if __name__ == "__main__":
    main()
