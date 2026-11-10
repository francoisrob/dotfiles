import json
import os
import tempfile
import unittest

import hermes_link as hl
from herdr_api import HerdrError

TICKS = os.sysconf("SC_CLK_TCK")
BOOT = 1_000_000
SESSION = "local-033c16c444acbbd818138abea77a1cb9250d171cc5faa6e6fd07043dbd2b72ae"


class FakeHerdr:
    def __init__(self):
        self.panes = {}
        self.reports = []
        self.fail = set()

    def request(self, method, params=None, timeout=10.0):
        if method == "pane.process_info":
            if params["pane_id"] in self.fail:
                raise HerdrError("pane.process_info: pane not found")
            return {"process_info": self.panes[params["pane_id"]]}
        if method == "pane.report_agent_session":
            self.reports.append(params)
            return {"type": "ok"}
        raise AssertionError(method)


def hermes_agent(pane, session=None):
    a = {"pane_id": pane, "agent": "hermes", "name": "hermes"}
    if session:
        a["agent_session"] = {"agent": "hermes", "kind": "id", "source": "herdr:hermes", "value": session}
    return a


class LinkerTest(unittest.TestCase):
    def setUp(self):
        self.root = tempfile.mkdtemp()
        self.proc = os.path.join(self.root, "proc")
        self.crumbs = os.path.join(self.root, "terminal-sessions")
        os.makedirs(self.crumbs)
        os.makedirs(self.proc)
        with open(os.path.join(self.proc, "stat"), "w") as fh:
            fh.write(f"cpu  1 2 3\nbtime {BOOT}\n")
        self.herdr = FakeHerdr()
        self.logs = []
        self.linker = hl.HermesLinker(self.herdr, self.crumbs, proc=self.proc, log=lambda lvl, t: self.logs.append(t))

    def process(self, pane, pid, name="hermes", stdin="/dev/pts/9", stdout=None, started=100.0):
        """A fake process started `started` seconds after boot, in the foreground of `pane`."""
        fd = os.path.join(self.proc, str(pid), "fd")
        os.makedirs(fd)
        os.symlink(stdin, os.path.join(fd, "0"))
        os.symlink(stdout or stdin, os.path.join(fd, "1"))
        fields = ["S"] + ["0"] * 18 + [str(int(started * TICKS))] + ["0"] * 5
        with open(os.path.join(self.proc, str(pid), "stat"), "w") as fh:
            fh.write(f"{pid} ({name}) " + " ".join(fields) + "\n")
        self.herdr.panes[pane] = {"foreground_process_group_id": pid, "foreground_processes": [{"pid": pid, "name": name}]}

    def crumb(self, tty="/dev/pts/9", session=SESSION, written=102.0, raw=None):
        with open(os.path.join(self.crumbs, hl.breadcrumb_name(tty)), "w") as fh:
            fh.write(raw if raw is not None else json.dumps({"session_id": session, "cwd": "/x", "ts": BOOT + written}))

    def test_file_name_follows_hermes_rule(self):
        self.assertEqual(hl.breadcrumb_name("/dev/pts/9"), "tty-dev-pts-9")
        self.assertEqual(hl.breadcrumb_name("/dev/tty1"), "tty-dev-tty1")

    def test_links_session_from_the_pane_terminal(self):
        self.process("wV:p1", 4242)
        self.crumb()
        agents = self.linker.sync([hermes_agent("wV:p1")])
        self.assertEqual(len(self.herdr.reports), 1)
        report = self.herdr.reports[0]
        self.assertEqual(
            {k: report[k] for k in ("pane_id", "source", "agent", "agent_session_id")},
            {"pane_id": "wV:p1", "source": "herdr:hermes", "agent": "hermes", "agent_session_id": SESSION},
        )
        self.assertIsInstance(report["seq"], int)
        self.assertEqual(agents[0]["agent_session"]["value"], SESSION)
        self.assertEqual(agents[0]["agent_session"]["kind"], "id")

    def test_known_session_is_not_reported_again(self):
        self.process("wV:p1", 4242)
        self.crumb()
        self.linker.sync([hermes_agent("wV:p1", session=SESSION)])
        self.assertEqual(self.herdr.reports, [])

    def test_changed_session_is_reported(self):
        self.process("wV:p1", 4242)
        self.crumb(session="local-new")
        agents = self.linker.sync([hermes_agent("wV:p1", session=SESSION)])
        self.assertEqual(self.herdr.reports[0]["agent_session_id"], "local-new")
        self.assertEqual(agents[0]["agent_session"]["value"], "local-new")

    def test_breadcrumb_from_before_the_process_started_is_ignored(self):
        self.process("wV:p1", 4242, started=500.0)
        self.crumb(written=400.0)  # an earlier Hermes on the same reused terminal
        agents = self.linker.sync([hermes_agent("wV:p1")])
        self.assertEqual(self.herdr.reports, [])
        self.assertNotIn("agent_session", agents[0])

    def test_breadcrumb_within_rounding_slack_counts(self):
        self.process("wV:p1", 4242, started=500.0)
        self.crumb(written=499.0)
        self.linker.sync([hermes_agent("wV:p1")])
        self.assertEqual(len(self.herdr.reports), 1)

    def test_pane_at_shell_is_skipped(self):
        self.process("wV:p1", 4242, name="fish")
        self.crumb()
        self.linker.sync([hermes_agent("wV:p1")])
        self.assertEqual(self.herdr.reports, [])

    def test_process_without_a_terminal_is_skipped(self):
        self.process("wV:p1", 4242, stdin="pipe:[123]", stdout="/dev/null")
        self.crumb()
        self.linker.sync([hermes_agent("wV:p1")])
        self.assertEqual(self.herdr.reports, [])

    def test_stdout_terminal_used_when_stdin_is_not_one(self):
        self.process("wV:p1", 4242, stdin="pipe:[123]", stdout="/dev/pts/9")
        self.crumb()
        self.linker.sync([hermes_agent("wV:p1")])
        self.assertEqual(len(self.herdr.reports), 1)

    def test_missing_or_broken_breadcrumb_is_skipped(self):
        self.process("wV:p1", 4242)
        self.linker.sync([hermes_agent("wV:p1")])
        for raw in ("{bad", "[]", json.dumps({"session_id": "", "ts": BOOT + 200}), json.dumps({"session_id": SESSION})):
            self.crumb(raw=raw)
            self.linker.sync([hermes_agent("wV:p1")])
        self.assertEqual(self.herdr.reports, [])

    def test_other_agents_untouched_and_one_failing_pane_does_not_stop_the_rest(self):
        self.process("wB:p1", 4243)
        self.crumb()
        self.herdr.fail.add("wA:p1")
        claude = {"pane_id": "wC:p1", "agent": "claude"}
        agents = self.linker.sync([hermes_agent("wA:p1"), claude, hermes_agent("wB:p1")])
        self.assertIs(agents[1], claude)
        self.assertEqual([r["pane_id"] for r in self.herdr.reports], ["wB:p1"])
        self.assertTrue(any("could not link" in t for t in self.logs))


if __name__ == "__main__":
    unittest.main()
