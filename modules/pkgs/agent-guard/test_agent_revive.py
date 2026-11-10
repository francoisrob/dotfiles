import json
import unittest
from contextlib import redirect_stdout
from io import StringIO

import agent_revive as ar
from oomkill import Kill

CLAUDE_SESSION = "83998870-430b-4f84-af44-c0bf14db2908"


def agent(pane, name="claude", kind="claude", session=CLAUDE_SESSION):
    a = {"pane_id": pane, "agent": kind, "name": name}
    if session:
        a["agent_session"] = {"agent": kind, "kind": "id", "source": f"herdr:{kind}", "value": session}
    return a


def proc_info(pgid, name, *children):
    processes = [{"pid": pgid, "name": name}] + [{"pid": pid, "name": n} for pid, n in children]
    return {"process_info": {"foreground_process_group_id": pgid, "foreground_processes": processes}}


class FakeHerdr:
    def __init__(self):
        self.agents = []
        self.panes = {}  # pane_id -> list of process_info replies, last one repeats
        self.started = []
        self.start_error = None

    def request(self, method, params=None, timeout=10.0):
        if method == "agent.list":
            return {"agents": self.agents}
        if method == "pane.process_info":
            replies = self.panes.get(params["pane_id"])
            if replies is None:
                raise ar.HerdrError("pane.process_info: pane not found")
            return replies.pop(0) if len(replies) > 1 else replies[0]
        if method == "agent.start":
            if self.start_error:
                raise ar.HerdrError(self.start_error)
            self.started.append(params)
            return {}
        raise AssertionError(method)


class Clock:
    def __init__(self):
        self.now = 0.0

    def __call__(self):
        return self.now

    def sleep(self, s):
        self.now += s


def kill(pid, name="claude", source="earlyoom"):
    return Kill(source=source, pid=pid, name=name, rss_mib=400)


class TrackerTest(unittest.TestCase):
    def setUp(self):
        self.herdr = FakeHerdr()
        self.clock = Clock()
        self.starts = {}
        self.tracker = ar.Tracker(self.herdr, clock=self.clock, linger=300, start_of=lambda pid: self.starts.get(pid, 1))

    def test_uses_given_agent_list_such_as_one_with_linked_hermes_sessions(self):
        self.herdr.agents = []  # agent.list would report nothing
        self.herdr.panes = {"wV:p1": [proc_info(77, "hermes")]}
        given = [agent("wV:p1", name="hermes", kind="hermes", session="local-abc")]
        self.assertEqual(self.tracker.refresh(given), 1)
        self.assertEqual(self.tracker.lookup(77).resume_args(), ["--resume", "local-abc"])

    def test_maps_agent_process_to_its_chat(self):
        self.herdr.agents = [agent("wF:p1")]
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude")]}
        self.assertEqual(self.tracker.refresh(), 1)
        t = self.tracker.lookup(4242)
        self.assertEqual(t, ar.Target("wF:p1", "claude", "claude", CLAUDE_SESSION, 4242))
        self.assertEqual(t.resume_args(), ["--resume", CLAUDE_SESSION])

    def test_every_process_of_the_foreground_group_maps_to_the_chat(self):
        self.herdr.agents = [agent("wF:p1")]
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude", (4300, "node"), (4301, "axiom"))]}
        self.assertEqual(self.tracker.refresh(), 1)
        for pid in (4242, 4300, 4301):
            self.assertEqual(self.tracker.lookup(pid).pgid, 4242)

    def test_lookup_consumes_entry(self):
        self.herdr.agents = [agent("wF:p1")]
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude")]}
        self.tracker.refresh()
        self.assertIsNotNone(self.tracker.lookup(4242))
        self.assertIsNone(self.tracker.lookup(4242))

    def test_skips_panes_without_session_unknown_kind_or_at_shell(self):
        self.herdr.agents = [
            agent("a:p1", session=None),
            agent("b:p1", kind="mystery"),
            agent("c:p1"),
            agent("d:p1"),
        ]
        self.herdr.panes = {"c:p1": [proc_info(10, "fish")]}  # d:p1 missing: process_info errors
        self.assertEqual(self.tracker.refresh(), 0)

    def test_agy_resume_args(self):
        self.herdr.agents = [agent("wC:p1", name="agy-2", kind="agy", session="062f")]
        self.herdr.panes = {"wC:p1": [proc_info(7, "agy")]}
        self.tracker.refresh()
        self.assertEqual(self.tracker.lookup(7).resume_args(), ["--conversation", "062f"])

    def test_entry_lingers_after_process_vanishes_then_expires(self):
        self.herdr.agents = [agent("wF:p1")]
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude")]}
        self.tracker.refresh()
        self.herdr.agents = []
        self.clock.now = 299
        self.tracker.refresh()
        self.assertIsNotNone(self.tracker.lookup(4242))

    def test_entry_expires_after_linger(self):
        self.herdr.agents = [agent("wF:p1")]
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude")]}
        self.tracker.refresh()
        self.herdr.agents = []
        self.clock.now = 301
        self.tracker.refresh()
        self.assertIsNone(self.tracker.lookup(4242))

    def test_reused_process_id_does_not_match(self):
        self.herdr.agents = [agent("wF:p1")]
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude")]}
        self.starts[4242] = 100
        self.tracker.refresh()
        self.starts[4242] = 999  # the id now belongs to a newer process
        self.assertIsNone(self.tracker.lookup(4242))

    def test_process_still_dying_matches(self):
        self.herdr.agents = [agent("wF:p1")]
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude")]}
        self.starts[4242] = 100
        self.tracker.refresh()
        self.assertIsNotNone(self.tracker.lookup(4242))

    def test_vanished_process_matches(self):
        self.herdr.agents = [agent("wF:p1")]
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude")]}
        self.starts[4242] = 100
        self.tracker.refresh()
        del self.starts[4242]
        self.starts = {}
        self.tracker.start_of = lambda pid: None
        self.assertIsNotNone(self.tracker.lookup(4242))

    def test_refresh_replaces_entry_when_id_was_reused_by_another_agent(self):
        self.herdr.agents = [agent("wF:p1")]
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude")]}
        self.starts[4242] = 100
        self.tracker.refresh()
        self.starts[4242] = 200
        self.tracker.refresh()
        self.assertIsNotNone(self.tracker.lookup(4242))


class ProcessStartTest(unittest.TestCase):
    def write(self, text):
        import os
        import tempfile

        d = tempfile.mkdtemp()
        os.mkdir(os.path.join(d, "42"))
        with open(os.path.join(d, "42", "stat"), "w") as fh:
            fh.write(text)
        return d

    def test_reads_start_time_even_when_name_has_spaces_and_parens(self):
        fields = " ".join(["S"] + [str(i) for i in range(4, 22)] + ["777"] + ["0"] * 5)
        d = self.write(f"42 (my (odd) name) {fields}\n")
        self.assertEqual(ar.process_start(42, d), 777)

    def test_missing_or_garbled_is_none(self):
        d = self.write("garbage")
        self.assertIsNone(ar.process_start(42, d))
        self.assertIsNone(ar.process_start(43, d))

    def test_real_process(self):
        import os

        self.assertIsInstance(ar.process_start(os.getpid()), int)


class ReviverTest(unittest.TestCase):
    def setUp(self):
        self.herdr = FakeHerdr()
        self.clock = Clock()
        self.mem = [0.5]
        self.dead = {4242}
        self.target = ar.Target("wF:p1", "claude", "claude", CLAUDE_SESSION, 4242)
        self.reviver = ar.Reviver(
            self.herdr,
            ar.Settings(),
            clock=self.clock,
            sleep=self.clock.sleep,
            mem_available=lambda: self.mem.pop(0) if len(self.mem) > 1 else self.mem[0],
            alive=lambda pid: pid not in self.dead,
        )
        self.out = StringIO()

    def revive(self, pid=4242):
        with redirect_stdout(self.out):
            return self.reviver.revive(self.target, kill(pid))

    def test_relaunches_with_resume_once_pane_is_at_shell(self):
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude"), proc_info(99, "fish")]}
        self.assertTrue(self.revive())
        self.assertEqual(
            self.herdr.started,
            [{"name": "claude", "kind": "claude", "pane_id": "wF:p1", "args": ["--resume", CLAUDE_SESSION], "timeout_ms": 120000}],
        )
        self.assertTrue(self.out.getvalue().startswith("<5>relaunched claude chat claude in pane wF:p1\n"))

    def test_waits_for_memory_to_recover_first(self):
        self.mem = [0.05, 0.10, 0.30]
        self.herdr.panes = {"wF:p1": [proc_info(99, "fish")]}
        self.assertTrue(self.revive())
        self.assertGreaterEqual(self.clock.now, 20)

    def test_relaunches_anyway_when_memory_never_recovers(self):
        self.mem = [0.01]
        self.herdr.panes = {"wF:p1": [proc_info(99, "fish")]}
        self.assertTrue(self.revive())
        self.assertIn("<4>memory still low", self.out.getvalue())

    def test_no_relaunch_when_pane_closed(self):
        self.herdr.panes = {}
        self.assertFalse(self.revive())
        self.assertEqual(self.herdr.started, [])
        self.assertIn("<6>not relaunching", self.out.getvalue())
        self.assertIn("pane was closed", self.out.getvalue())

    def test_no_relaunch_when_something_else_runs_in_pane(self):
        self.herdr.panes = {"wF:p1": [proc_info(555, "vim")]}
        self.assertFalse(self.revive())
        self.assertEqual(self.herdr.started, [])
        self.assertIn("something else runs", self.out.getvalue())

    def test_no_relaunch_while_agent_still_alive(self):
        self.dead = set()  # SIGTERM was ignored, the agent is still running
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude")]}
        self.assertFalse(self.revive())
        self.assertEqual(self.herdr.started, [])
        self.assertIn("<3>could not relaunch", self.out.getvalue())

    def test_gives_up_after_three_kills_in_window(self):
        self.herdr.panes = {"wF:p1": [proc_info(99, "fish")]}
        for _ in range(3):
            self.assertTrue(self.revive())
            self.clock.now += 60
        self.assertFalse(self.revive())
        self.assertEqual(len(self.herdr.started), 3)
        self.assertIn("<3>gave up relaunching", self.out.getvalue())

    def test_counter_resets_after_window(self):
        self.herdr.panes = {"wF:p1": [proc_info(99, "fish")]}
        for _ in range(3):
            self.revive()
        self.clock.now += 1801
        self.assertTrue(self.revive())

    def test_parallel_relaunch_of_same_pane_refused_without_an_alert(self):
        self.herdr.panes = {"wF:p1": [proc_info(99, "fish")]}
        self.reviver.busy.add("wF:p1")
        self.assertFalse(self.revive())
        self.assertIn("<6>not relaunching", self.out.getvalue())
        self.assertIn("already in progress", self.out.getvalue())
        self.assertEqual(self.herdr.started, [])

    def test_kill_of_agent_child_does_not_relaunch_or_use_up_a_try(self):
        self.dead = {4300}
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude", (4301, "axiom"))]}
        self.assertFalse(self.revive(4300))
        self.assertEqual(self.herdr.started, [])
        self.assertIn("only a process of it was killed", self.out.getvalue())
        self.assertNotIn("<3>", self.out.getvalue())
        self.assertEqual(self.reviver.history, {})
        self.assertGreaterEqual(self.clock.now, self.reviver.settings.settle)

    def test_kill_of_wrapped_agent_relaunches_once_its_leader_exits_too(self):
        self.dead = {4300}
        self.herdr.panes = {
            "wF:p1": [proc_info(4242, "node", (4300, "claude")), proc_info(4242, "node", (4300, "claude")), proc_info(99, "fish")]
        }
        self.assertTrue(self.revive(4300))
        self.assertEqual(len(self.herdr.started), 1)

    def test_pane_must_still_be_at_shell_after_the_memory_wait(self):
        self.mem = [0.05, 0.30]
        self.herdr.panes = {"wF:p1": [proc_info(99, "fish"), proc_info(555, "vim")]}
        self.assertFalse(self.revive())
        self.assertEqual(self.herdr.started, [])
        self.assertIn("something else runs", self.out.getvalue())
        self.assertNotIn("wF:p1", self.reviver.busy)

    def test_start_failure_reported_and_pane_released(self):
        self.herdr.panes = {"wF:p1": [proc_info(99, "fish")]}
        self.herdr.start_error = "agent.start: timed out"
        self.assertFalse(self.revive())
        self.assertIn("<3>could not relaunch", self.out.getvalue())
        self.assertNotIn("wF:p1", self.reviver.busy)


class HandleLineTest(unittest.TestCase):
    def setUp(self):
        self.herdr = FakeHerdr()
        self.herdr.agents = [agent("wF:p1")]
        self.herdr.panes = {"wF:p1": [proc_info(4242, "claude", (5000, "bun"))]}
        self.tracker = ar.Tracker(self.herdr, start_of=lambda pid: 1)
        self.tracker.refresh()
        self.calls = []

    def feed(self, entry):
        line = entry if isinstance(entry, str) else json.dumps(entry)
        return ar.handle_line(line, self.tracker, lambda t, k: self.calls.append((t, k)))

    def test_earlyoom_kill_of_agent_triggers_revive(self):
        msg = 'sending SIGTERM to process 4242 uid 1000 "claude": oom_score 501, oom_score_adj 200, VmRSS 400 MiB, cmdline "claude"'
        self.assertIsNotNone(self.feed({"SYSLOG_IDENTIFIER": "earlyoom", "MESSAGE": msg}))
        self.assertEqual(self.calls[0][0].pane_id, "wF:p1")

    def test_kernel_kill_of_agent_triggers_revive(self):
        msg = "Out of memory: Killed process 4242 (claude) total-vm:1kB, anon-rss:409600kB, file-rss:0kB"
        self.feed({"_TRANSPORT": "kernel", "MESSAGE": msg})
        self.assertEqual(len(self.calls), 1)

    def test_kill_of_agent_group_member_is_handed_to_the_reviver(self):
        msg = 'sending SIGTERM to process 5000 uid 1000 "bun": oom_score 900, oom_score_adj 200, VmRSS 9000 MiB'
        self.assertIsNotNone(self.feed({"SYSLOG_IDENTIFIER": "earlyoom", "MESSAGE": msg}))
        self.assertEqual(self.calls[0][1].pid, 5000)

    def test_kill_of_unrelated_process_is_ignored(self):
        msg = 'sending SIGTERM to process 6000 uid 1000 "bun": oom_score 900, oom_score_adj 200, VmRSS 9000 MiB'
        self.assertIsNone(self.feed({"SYSLOG_IDENTIFIER": "earlyoom", "MESSAGE": msg}))
        self.assertEqual(self.calls, [])

    def test_noise_ignored(self):
        self.assertIsNone(self.feed(""))
        self.assertIsNone(self.feed("{bad"))
        self.assertIsNone(self.feed({"SYSLOG_IDENTIFIER": "earlyoom", "MESSAGE": "mem avail: 50%"}))
        self.assertEqual(self.calls, [])

    def test_journal_command_starts_at_end(self):
        cmd = ar.journalctl_command("journalctl")
        self.assertIn("--lines=0", cmd)
        self.assertIn("SYSLOG_IDENTIFIER=earlyoom", cmd)


class MemInfoTest(unittest.TestCase):
    def test_reads_available_fraction(self):
        import tempfile

        with tempfile.NamedTemporaryFile("w", suffix="meminfo", delete=False) as fh:
            fh.write("MemTotal:       1000 kB\nMemFree:  100 kB\nMemAvailable:    250 kB\n")
        self.assertAlmostEqual(ar.mem_available_fraction(fh.name), 0.25)


class HerdrClientTest(unittest.TestCase):
    def test_round_trip_and_error_over_a_real_socket(self):
        import os
        import socket
        import tempfile
        import threading

        d = tempfile.mkdtemp()
        path = os.path.join(d, "s")
        server = socket.socket(socket.AF_UNIX)
        server.bind(path)
        server.listen()

        def serve():
            for reply in ({"id": "x", "result": {"agents": []}}, {"id": "y", "error": {"message": "pane not found"}}):
                conn, _ = server.accept()
                req = json.loads(conn.makefile().readline())
                assert req["method"] in ("agent.list", "pane.get")
                conn.sendall((json.dumps(reply) + "\n").encode())
                conn.close()

        threading.Thread(target=serve, daemon=True).start()
        client = ar.HerdrClient(path)
        self.assertEqual(client.request("agent.list"), {"agents": []})
        with self.assertRaisesRegex(ar.HerdrError, "pane not found"):
            client.request("pane.get", {"pane_id": "zz"})
        server.close()


if __name__ == "__main__":
    unittest.main()
