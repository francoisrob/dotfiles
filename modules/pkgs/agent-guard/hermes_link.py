"""Tell herdr which Hermes session runs in each pane, so herdr can resume it.

herdr's own Hermes plugin reports the session from inside the Hermes process, using the pane id in
that process's environment. With the Hermes gateway running, the `hermes` command in a pane is only
a client: the session runs in the gateway service, which has no pane id, so the plugin never
reports and herdr has nothing to resume.

The client does record its session per terminal: Hermes writes a breadcrumb file named after the
terminal device (~/.hermes/terminal-sessions/tty-dev-pts-9) holding the session id, so that
`hermes -c` in the same terminal continues it. This module follows the chain herdr pane ->
the Hermes process in it -> that process's terminal -> its breadcrumb, and reports the session id
with herdr's pane.report_agent_session. A breadcrumb written before the process started belongs to
an earlier program on a reused terminal and is ignored.
"""

import json
import os
import re
import time

from herdr_api import HerdrError

SOURCE = "herdr:hermes"
AGENT = "hermes"
SHELLS = {"fish", "bash", "zsh", "sh", "dash", "nu", "elvish", "xonsh"}
# Process start times come from whole-second boot time plus clock ticks, so allow some rounding.
START_SLACK = 2.0
# Hermes's breadcrumb file name rule (hermes_cli/terminal_breadcrumbs.py: _sanitize).
_SANITIZE = re.compile(r"[^A-Za-z0-9._-]")


def breadcrumb_name(tty):
    return "tty-" + _SANITIZE.sub("-", tty.strip().strip("/"))[:120]


def terminal_of(pid, proc="/proc"):
    """The terminal device of a process, checked on stdin then stdout, as Hermes does. None if neither is one."""
    for fd in (0, 1):
        try:
            target = os.readlink(f"{proc}/{pid}/fd/{fd}")
        except OSError:
            continue
        if target.startswith(("/dev/pts/", "/dev/tty")):
            return target
    return None


def started_at(pid, proc="/proc"):
    """Wall-clock start time of a process in seconds, or None if it is gone."""
    try:
        with open(f"{proc}/{pid}/stat", encoding="ascii") as fh:
            fields = fh.read().rsplit(")", 1)[1].split()
        with open(f"{proc}/stat", encoding="ascii") as fh:
            boot = next(float(line.split()[1]) for line in fh if line.startswith("btime "))
    except (OSError, IndexError, StopIteration, ValueError):
        return None
    # Field 22 of /proc/<pid>/stat (starttime); fields here start after the command name, at field 3.
    return boot + int(fields[19]) / os.sysconf("SC_CLK_TCK")


def read_breadcrumb(path):
    """(session_id, written_at) from a breadcrumb file, or None when missing or malformed."""
    try:
        with open(path, encoding="utf-8-sig") as fh:
            data = json.load(fh)
    except (OSError, ValueError):
        return None
    if not isinstance(data, dict):
        return None
    session = data.get("session_id")
    written = data.get("ts")
    if not isinstance(session, str) or not session.strip() or not isinstance(written, (int, float)):
        return None
    return session.strip(), float(written)


class HermesLinker:
    def __init__(self, herdr, breadcrumbs_dir, proc="/proc", log=None):
        self.herdr = herdr
        self.breadcrumbs_dir = breadcrumbs_dir
        self.proc = proc
        self.log = log or (lambda level, text: None)

    def session_in(self, pane_id):
        """The Hermes session id running in a pane, or None when it cannot be proven."""
        info = self.herdr.request("pane.process_info", {"pane_id": pane_id}).get("process_info", {})
        pgid = info.get("foreground_process_group_id")
        leader = next((p for p in info.get("foreground_processes", []) if p.get("pid") == pgid), None)
        if not pgid or not leader or leader.get("name") in SHELLS:
            return None
        tty = terminal_of(pgid, self.proc)
        started = started_at(pgid, self.proc)
        if tty is None or started is None:
            return None
        crumb = read_breadcrumb(os.path.join(self.breadcrumbs_dir, breadcrumb_name(tty)))
        if crumb is None or crumb[1] < started - START_SLACK:
            return None
        return crumb[0]

    def sync(self, agents):
        """Report the session of every Hermes pane whose herdr record is missing or out of date.
        Returns the agent list with the reported sessions filled in."""
        updated = []
        for agent in agents:
            if agent.get("agent") != AGENT:
                updated.append(agent)
                continue
            pane = agent.get("pane_id")
            known = (agent.get("agent_session") or {}).get("value")
            try:
                session = self.session_in(pane)
                if session and session != known:
                    self.herdr.request(
                        "pane.report_agent_session",
                        {
                            "pane_id": pane,
                            "source": SOURCE,
                            "agent": AGENT,
                            "seq": time.time_ns(),
                            "agent_session_id": session,
                        },
                    )
                    self.log("<6>", f"linked hermes chat in pane {pane} to session {session}")
                    agent = {**agent, "agent_session": {"agent": AGENT, "kind": "id", "source": SOURCE, "value": session}}
            except HerdrError as err:
                self.log("<6>", f"could not link hermes chat in pane {pane}: {err}")
            updated.append(agent)
        return updated
