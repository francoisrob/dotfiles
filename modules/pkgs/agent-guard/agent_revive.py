"""Relaunch herdr agent chats that a memory killer took down, in the same pane, resuming the same session.

herdr resumes agent conversations only when the herdr server itself restarts. When earlyoom or
the kernel kills one agent process, its pane just drops back to the shell. This service:

1. keeps a map of which process is which agent chat, from herdr's own API
   (agent.list for the session reference, pane.process_info for the agent's process group);
2. follows the journal for memory kills (earlyoom, kernel OOM);
3. when a killed process is a tracked agent, waits for memory to recover and for the pane to be
   back at its shell, then starts the same agent with its resume arguments via herdr agent.start.

It never touches a chat that ended any other way (you quit it, it crashed on its own), a pane
that was closed, or a pane where something else is already running. A pane that keeps getting
killed is given up on after a few tries, so it cannot loop.

It also links Hermes chats to their session (see hermes_link), since herdr's Hermes plugin cannot
while the Hermes gateway runs the sessions. That is what gives Hermes panes a session to resume.

Outcomes go to the journal with a syslog priority prefix; kill-alerts forwards the notices.
"""

import argparse
import json
import os
import select
import subprocess
import sys
import threading
import time
from dataclasses import dataclass, field

from herdr_api import HerdrClient, HerdrError
from hermes_link import HermesLinker
from oomkill import JOURNAL_FILTERS, parse_kill

# Resume arguments per herdr agent kind, from herdr's native session restore table.
RESUME_ARGS = {
    "claude": ["--resume", "{id}"],
    "agy": ["--conversation", "{id}"],
    "codex": ["resume", "{id}"],
    "pi": ["--session", "{id}"],
    "omp": ["--resume={id}"],
    "cursor": ["--resume", "{id}"],
    "grok": ["--resume", "{id}"],
    "copilot": ["--resume={id}"],
    "devin": ["--resume", "{id}"],
    "droid": ["--resume", "{id}"],
    "kimi": ["--session", "{id}"],
    "qodercli": ["--resume", "{id}"],
    "qwen": ["--resume", "{id}"],
    "opencode": ["--session", "{id}"],
    "kilo": ["--session", "{id}"],
    "hermes": ["--resume", "{id}"],
    "mastracode": ["--thread", "{id}"],
}
SHELLS = {"fish", "bash", "zsh", "sh", "dash", "nu", "elvish", "xonsh"}

# syslog priority prefixes read by journald (SyslogLevelPrefix).
ERR, WARNING, NOTICE, INFO = "<3>", "<4>", "<5>", "<6>"


BUSY = object()

AT_SHELL, WAITING, AGENT_RUNNING, OTHER_RUNNING, PANE_GONE = "shell", "waiting", "agent", "other", "gone"
NO_RELAUNCH = {
    AGENT_RUNNING: "the agent is still running, only a process of it was killed",
    OTHER_RUNNING: "something else runs in the pane now",
    PANE_GONE: "the pane was closed",
}


def log(level, text):
    print(f"{level}{text}", flush=True)


@dataclass(frozen=True)
class Target:
    """One agent chat: where it runs and how to resume it."""

    pane_id: str
    name: str
    kind: str
    session_id: str
    pgid: int = 0

    def resume_args(self):
        return [a.replace("{id}", self.session_id) for a in RESUME_ARGS[self.kind]]


@dataclass
class Seen:
    target: Target
    started: object
    last_seen: float


def process_start(pid, proc="/proc"):
    """The kernel start time of a process in clock ticks, or None when it does not exist.

    A process id plus its start time names one process for the life of the machine.
    """
    try:
        with open(f"{proc}/{pid}/stat", encoding="utf-8", errors="replace") as fh:
            stat = fh.read()
    except OSError:
        return None
    try:
        return int(stat[stat.rindex(")") + 2 :].split()[19])
    except (ValueError, IndexError):
        return None


class Tracker:
    """Which process id is which agent chat. Every process of the agent's foreground group is
    tracked, so a kill of the agent or of a wrapper around it both find the chat. Entries outlive
    the process briefly, so a kill read from the journal just after the process vanished still finds
    its chat. An id that now belongs to a different process (reused) never matches."""

    def __init__(self, herdr, clock=time.monotonic, linger=60.0, start_of=process_start):
        self.herdr = herdr
        self.clock = clock
        self.linger = linger
        self.start_of = start_of
        self.by_pid = {}
        self.lock = threading.Lock()

    def refresh(self, agents=None):
        if agents is None:
            agents = self.herdr.request("agent.list").get("agents", [])
        now = self.clock()
        found = {}
        for agent in agents:
            session = agent.get("agent_session") or {}
            kind = session.get("agent") or agent.get("agent")
            if session.get("kind") != "id" or not session.get("value") or kind not in RESUME_ARGS:
                continue
            try:
                info = self.herdr.request("pane.process_info", {"pane_id": agent["pane_id"]}).get("process_info", {})
            except HerdrError:
                continue
            pgid = info.get("foreground_process_group_id")
            processes = info.get("foreground_processes", [])
            leader = next((p for p in processes if p.get("pid") == pgid), None)
            if not pgid or not leader or leader.get("name") in SHELLS:
                continue
            target = Target(agent["pane_id"], agent.get("name") or kind, kind, session["value"], pgid)
            for p in processes:
                if isinstance(p.get("pid"), int):
                    found[p["pid"]] = target
        with self.lock:
            for pid, target in found.items():
                started = self.start_of(pid)
                previous = self.by_pid.get(pid)
                if previous and previous.target == target and previous.started == started:
                    previous.last_seen = now
                else:
                    self.by_pid[pid] = Seen(target, started, now)
            for pid in [p for p, s in self.by_pid.items() if now - s.last_seen > self.linger]:
                del self.by_pid[pid]
        return len({t.pane_id for t in found.values()})

    def lookup(self, pid):
        with self.lock:
            seen = self.by_pid.pop(pid, None)
        if not seen:
            return None
        now_started = self.start_of(pid)
        if now_started is not None and now_started != seen.started:
            return None
        return seen.target


def mem_available_fraction(path="/proc/meminfo"):
    values = {}
    with open(path, encoding="ascii") as fh:
        for line in fh:
            key, _, rest = line.partition(":")
            values[key] = int(rest.split()[0])
    return values["MemAvailable"] / values["MemTotal"]


def pid_alive(pid):
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


@dataclass
class Settings:
    min_available: float = 0.20
    memory_wait: float = 600.0
    shell_wait: float = 60.0
    settle: float = 6.0
    poll: float = 2.0
    max_relaunches: int = 3
    window: float = 1800.0
    start_timeout_ms: int = 120000


@dataclass
class Reviver:
    herdr: HerdrClient
    settings: Settings = field(default_factory=Settings)
    clock: object = time.monotonic
    sleep: object = time.sleep
    mem_available: object = mem_available_fraction
    alive: object = pid_alive
    history: dict = field(default_factory=dict)
    busy: set = field(default_factory=set)
    lock: threading.Lock = field(default_factory=threading.Lock)

    def claim(self, target):
        """Reserve a relaunch for this pane, or explain why not."""
        now = self.clock()
        with self.lock:
            if target.pane_id in self.busy:
                return BUSY
            recent = [t for t in self.history.get(target.pane_id, []) if now - t < self.settings.window]
            if len(recent) >= self.settings.max_relaunches:
                self.history[target.pane_id] = recent
                return f"it was killed {len(recent)} times in {int(self.settings.window // 60)} minutes"
            self.history[target.pane_id] = recent + [now]
            self.busy.add(target.pane_id)
        return None

    def release(self, target):
        with self.lock:
            self.busy.discard(target.pane_id)

    def wait_for_memory(self):
        deadline = self.clock() + self.settings.memory_wait
        while self.mem_available() < self.settings.min_available:
            if self.clock() >= deadline:
                return False
            self.sleep(self.settings.poll * 5)
        return True

    def probe(self, target, victim):
        """Where the pane stands after the kill of process id `victim` of its agent."""
        try:
            info = self.herdr.request("pane.process_info", {"pane_id": target.pane_id}).get("process_info", {})
        except HerdrError as err:
            if "not found" in str(err).lower() or "unknown pane" in str(err).lower():
                return PANE_GONE
            return WAITING
        pgid = info.get("foreground_process_group_id")
        leader = next((p for p in info.get("foreground_processes", []) if p.get("pid") == pgid), None)
        if not leader:
            return WAITING
        if pgid == target.pgid and victim != pgid:
            return AGENT_RUNNING
        if self.alive(victim):
            return WAITING
        if leader.get("name") in SHELLS:
            return AT_SHELL
        return AGENT_RUNNING if pgid == target.pgid else OTHER_RUNNING

    def wait_for_shell(self, target, victim):
        """The probe result once it is settled: AT_SHELL, a result that rules out a relaunch, or
        WAITING when the pane never got back to a shell in time. A kill of a process other than
        the group leader gets `settle` seconds for the leader to exit too before the agent counts as running."""
        started = self.clock()
        deadline = started + self.settings.shell_wait
        while True:
            state = self.probe(target, victim)
            if state == AGENT_RUNNING and self.clock() - started < self.settings.settle:
                state = WAITING
            if state != WAITING or self.clock() >= deadline:
                return state
            self.sleep(self.settings.poll)

    def revive(self, target, kill):
        where = f"{target.kind} chat {target.name} in pane {target.pane_id}"
        detail = f"session {target.session_id}, {kill.name} pid {kill.pid} killed by {kill.source}"
        try:
            state = self.wait_for_shell(target, kill.pid)
            if state in NO_RELAUNCH:
                log(INFO, f"not relaunching {where}: {NO_RELAUNCH[state]}")
                return False
            if state == WAITING:
                log(ERR, f"could not relaunch {where}\nthe pane did not return to a shell; {detail}")
                return False
            refused = self.claim(target)
            if refused is BUSY:
                log(INFO, f"not relaunching {where}: a relaunch is already in progress")
                return False
            if refused:
                log(ERR, f"gave up relaunching {where}\n{refused}; {detail}")
                return False
            try:
                if not self.wait_for_memory():
                    log(WARNING, f"memory still low after {int(self.settings.memory_wait)} s, relaunching {where} anyway")
                state = self.probe(target, kill.pid)
                if state != AT_SHELL:
                    log(INFO, f"not relaunching {where}: {NO_RELAUNCH.get(state, 'the pane is not at a shell')}")
                    return False
                self.herdr.request(
                    "agent.start",
                    {
                        "name": target.name,
                        "kind": target.kind,
                        "pane_id": target.pane_id,
                        "args": target.resume_args(),
                        "timeout_ms": self.settings.start_timeout_ms,
                    },
                    timeout=self.settings.start_timeout_ms / 1000 + 10,
                )
                log(NOTICE, f"relaunched {where}\n{detail}")
                return True
            finally:
                self.release(target)
        except HerdrError as err:
            log(ERR, f"could not relaunch {where}\n{err}; {detail}")
            return False


def journalctl_command(journalctl):
    # Only kills from now on: a kill from before this service started is not ours to act on.
    return [journalctl, "--follow", "--output=json", "--merge", "--lines=0"] + JOURNAL_FILTERS


def handle_line(line, tracker, start_revive):
    if not line.strip():
        return None
    try:
        entry = json.loads(line)
    except json.JSONDecodeError:
        return None
    kill = parse_kill(entry)
    if not kill:
        return None
    target = tracker.lookup(kill.pid)
    if target:
        start_revive(target, kill)
    return target


def run(args):
    herdr = HerdrClient(args.socket)
    tracker = Tracker(herdr)
    linker = HermesLinker(herdr, os.path.join(args.hermes_home, "terminal-sessions"), log=log)
    reviver = Reviver(herdr, Settings(min_available=args.min_available))

    def start_revive(target, kill):
        threading.Thread(target=reviver.revive, args=(target, kill), daemon=True).start()

    proc = subprocess.Popen(journalctl_command(args.journalctl), stdout=subprocess.PIPE)
    fd = proc.stdout.fileno()
    buffer, next_refresh, herdr_down = b"", 0.0, False
    while True:
        now = time.monotonic()
        if now >= next_refresh:
            try:
                agents = herdr.request("agent.list").get("agents", [])
                tracker.refresh(linker.sync(agents))
                if herdr_down:
                    log(INFO, "herdr is reachable again")
                herdr_down = False
            except HerdrError as err:
                if not herdr_down:
                    log(INFO, f"herdr not reachable, will keep trying: {err}")
                herdr_down = True
            next_refresh = now + args.refresh
        ready, _, _ = select.select([fd], [], [], 1.0)
        if ready:
            chunk = os.read(fd, 65536)
            if not chunk:
                proc.wait()
                raise SystemExit(f"journalctl exited with {proc.returncode}")
            buffer += chunk
            *lines, buffer = buffer.split(b"\n")
            for line in lines:
                handle_line(line.decode("utf-8", errors="replace"), tracker, start_revive)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--journalctl", default="journalctl")
    parser.add_argument(
        "--socket",
        default=os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser("~/.config/herdr/herdr.sock"),
    )
    parser.add_argument(
        "--hermes-home",
        default=os.environ.get("HERMES_HOME") or os.path.expanduser("~/.hermes"),
        help="Hermes home directory, for its per-terminal session breadcrumbs",
    )
    parser.add_argument("--refresh", type=float, default=3.0, help="seconds between agent map refreshes")
    parser.add_argument("--min-available", type=float, default=0.20, help="free memory fraction to wait for")
    args = parser.parse_args(argv)
    run(args)


if __name__ == "__main__":
    sys.exit(main())
