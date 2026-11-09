"""Read memory kills (earlyoom and the kernel OOM killer) out of systemd journal entries."""

import re
from dataclasses import dataclass

EARLYOOM_KILL = re.compile(
    r'^sending (?P<signal>SIG[A-Z]+) to process (?P<pid>\d+) uid (?P<uid>\d+) '
    r'"(?P<name>[^"]*)": oom_score (?P<score>-?\d+), oom_score_adj (?P<adj>-?\d+), '
    r'VmRSS (?P<rss>\d+) MiB(?:, cmdline "(?P<cmdline>.*)")?'
)
KERNEL_KILL = re.compile(
    r'(?P<scope>Memory cgroup out of memory|Out of memory): Killed process '
    r'(?P<pid>\d+) \((?P<name>[^)]*)\).*?anon-rss:(?P<rss>\d+)kB'
)

# journalctl matches for every entry parse_kill() can read ('+' separates OR-ed groups).
JOURNAL_FILTERS = ["SYSLOG_IDENTIFIER=earlyoom", "+", "_TRANSPORT=kernel"]


@dataclass(frozen=True)
class Kill:
    source: str  # "earlyoom" or "kernel"
    pid: int
    name: str
    rss_mib: int
    signal: str = "SIGKILL"
    uid: str = ""
    score: str = ""
    cmdline: str = ""
    cgroup_limit: bool = False


def message_text(entry):
    """The MESSAGE of a journal entry as text (journalctl prints non-UTF-8 ones as byte lists)."""
    message = entry.get("MESSAGE", "")
    if isinstance(message, list):
        message = bytes(message).decode("utf-8", errors="replace")
    return str(message)


def parse_kill(entry):
    """Return the Kill an entry reports, or None when it reports none."""
    message = message_text(entry)
    if entry.get("SYSLOG_IDENTIFIER") == "earlyoom":
        m = EARLYOOM_KILL.match(message)
        if not m:
            return None
        return Kill(
            source="earlyoom",
            pid=int(m["pid"]),
            name=m["name"],
            rss_mib=int(m["rss"]),
            signal=m["signal"],
            uid=m["uid"],
            score=m["score"],
            cmdline=m["cmdline"] or "",
        )
    if entry.get("_TRANSPORT") == "kernel":
        m = KERNEL_KILL.search(message)
        if not m:
            return None
        return Kill(
            source="kernel",
            pid=int(m["pid"]),
            name=m["name"],
            rss_mib=int(m["rss"]) // 1024,
            cgroup_limit=m["scope"].startswith("Memory cgroup"),
        )
    return None
