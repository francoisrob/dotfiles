import contextlib
import io
import json
import os
import tempfile
import unittest
import urllib.error

import kill_alerts as ka

WATCHED = {"herdr.service", "llama-server.service"}

# Real journal lines from minipc.
EARLYOOM_BUN = (
    'sending SIGTERM to process 1793049 uid 1000 "bun": oom_score 944, oom_score_adj 200, '
    'VmRSS 9213 MiB, cmdline "/home/francois/.local/share/mise/installs/bun/1.3.14/bin/bun '
    'test src/migration/group-cycles.test.ts"'
)
KERNEL_CGROUP = (
    "Memory cgroup out of memory: Killed process 2904171 (bun) total-vm:78678620kB, "
    "anon-rss:3122300kB, file-rss:43324kB, shmem-rss:0kB, UID:1000 pgtables:7392kB oom_score_adj:200"
)


def user_unit(message_id, unit="herdr.service", **extra):
    return {"MESSAGE_ID": message_id, "USER_UNIT": unit, "MESSAGE": f"{unit}: something", **extra}


class ClassifyTest(unittest.TestCase):
    def test_earlyoom_kill(self):
        e = ka.classify({"SYSLOG_IDENTIFIER": "earlyoom", "MESSAGE": EARLYOOM_BUN}, WATCHED)
        self.assertEqual(e.title, "earlyoom killed bun")
        self.assertIn("SIGTERM pid 1793049", e.body)
        self.assertIn("9213 MiB", e.body)
        self.assertIn("group-cycles.test.ts", e.body)
        self.assertEqual(e.priority, 4)

    def test_earlyoom_kill_without_cmdline(self):
        msg = 'sending SIGKILL to process 7 uid 0 "x": oom_score 1, oom_score_adj 0, VmRSS 3 MiB'
        e = ka.classify({"SYSLOG_IDENTIFIER": "earlyoom", "MESSAGE": msg}, WATCHED)
        self.assertEqual(e.body, "SIGKILL pid 7 uid 0, 3 MiB, oom_score 1")

    def test_earlyoom_status_lines_ignored(self):
        for msg in [
            "mem avail: 11828 of 27656 MiB (42.77%), swap free: 9800 of 15000 MiB (65.33%)",
            "kill_release: pid=3629: process_mrelease pidfd=4 failed: Invalid argument",
            "sending SIGTERM when mem avail <= 10.00% and swap free <= 50.00%,",
        ]:
            self.assertIsNone(ka.classify({"SYSLOG_IDENTIFIER": "earlyoom", "MESSAGE": msg}, WATCHED))

    def test_kernel_cgroup_kill(self):
        e = ka.classify({"_TRANSPORT": "kernel", "MESSAGE": KERNEL_CGROUP}, WATCHED)
        self.assertEqual(e.title, "kernel killed bun")
        self.assertEqual(e.body, "pid 2904171, 3049 MiB, cgroup limit")
        self.assertEqual(e.priority, 5)

    def test_kernel_global_kill(self):
        msg = "Out of memory: Killed process 42 (mongod) total-vm:1kB, anon-rss:2048kB, file-rss:0kB"
        e = ka.classify({"_TRANSPORT": "kernel", "MESSAGE": msg}, WATCHED)
        self.assertEqual(e.body, "pid 42, 2 MiB, system out of memory")

    def test_other_kernel_lines_ignored(self):
        self.assertIsNone(ka.classify({"_TRANSPORT": "kernel", "MESSAGE": "usb 1-1: new device"}, WATCHED))

    def test_oomd_kill(self):
        e = ka.classify(user_unit(ka.MSG_OOMD_KILL), WATCHED)
        self.assertEqual(e.title, "systemd-oomd killed herdr.service (user)")
        self.assertEqual(e.priority, 5)

    def test_process_oom_inside_unit(self):
        e = ka.classify(user_unit(ka.MSG_UNIT_OOM), WATCHED)
        self.assertEqual(e.title, "OOM kill inside herdr.service (user)")

    def test_crash_result_reported_for_any_unit(self):
        entry = {"MESSAGE_ID": ka.MSG_UNIT_FAILED, "UNIT": "foo.service", "UNIT_RESULT": "signal", "MESSAGE": "m"}
        self.assertEqual(ka.classify(entry, WATCHED).title, "foo.service failed (signal)")

    def test_plain_failure_only_for_watched_units(self):
        failed = {"MESSAGE_ID": ka.MSG_UNIT_FAILED, "UNIT_RESULT": "exit-code", "MESSAGE": "m"}
        self.assertIsNone(ka.classify({**failed, "UNIT": "scratch-clean.service"}, WATCHED))
        self.assertIsNotNone(ka.classify({**failed, "USER_UNIT": "llama-server.service"}, WATCHED))

    def test_restart_only_for_watched_units(self):
        e = ka.classify(user_unit(ka.MSG_UNIT_RESTART, N_RESTARTS="1"), WATCHED)
        self.assertEqual(e.title, "herdr.service (user) restarting (restart 1)")
        self.assertIsNone(ka.classify(user_unit(ka.MSG_UNIT_RESTART, unit="other.service"), WATCHED))

    def test_unrelated_entries_ignored(self):
        self.assertIsNone(ka.classify({"MESSAGE": "hello"}, WATCHED))
        self.assertIsNone(ka.classify({"MESSAGE_ID": "0" * 32, "UNIT": "a.service", "MESSAGE": "x"}, WATCHED))

    def test_long_text_clipped(self):
        msg = EARLYOOM_BUN.replace("group-cycles", "x" * 2000)
        e = ka.classify({"SYSLOG_IDENTIFIER": "earlyoom", "MESSAGE": msg}, WATCHED)
        self.assertLessEqual(len(e.body.splitlines()[1]), ka.MAX_LINE_CHARS)


class SummarizeTest(unittest.TestCase):
    def ev(self, n, prio=3):
        return ka.Event(f"t{n}", f"b{n}\nmore", prio, f"tag{n % 2}")

    def test_single_event(self):
        self.assertEqual(ka.summarize([self.ev(1, 4)], "minipc"), ("minipc: t1", "b1\nmore", 4, ["tag1"]))

    def test_burst_uses_max_priority_and_first_lines(self):
        title, body, prio, tags = ka.summarize([self.ev(1), self.ev(2, 5)], "minipc")
        self.assertEqual(title, "minipc: 2 kill/crash events")
        self.assertEqual(body, "• t1: b1\n• t2: b2")
        self.assertEqual(prio, 5)
        self.assertEqual(tags, ["tag0", "tag1"])

    def test_burst_is_capped(self):
        _, body, _, _ = ka.summarize([self.ev(i) for i in range(30)], "h")
        self.assertEqual(len(body.splitlines()), ka.MAX_LINES + 1)
        self.assertTrue(body.endswith("… and 10 more"))


class JournalAndCursorTest(unittest.TestCase):
    def test_command_starts_at_end_without_cursor(self):
        cmd = ka.journalctl_command("/bin/journalctl", None)
        self.assertIn("--lines=0", cmd)
        self.assertNotIn("+", cmd[:4])
        self.assertEqual(cmd[-1], "_TRANSPORT=kernel")

    def test_command_resumes_after_cursor(self):
        cmd = ka.journalctl_command("journalctl", "s=abc")
        self.assertIn("--after-cursor=s=abc", cmd)
        self.assertNotIn("--lines=0", cmd)

    def test_cursor_round_trip(self):
        with tempfile.TemporaryDirectory() as d:
            path = os.path.join(d, "cursor")
            self.assertIsNone(ka.read_cursor(path))
            ka.write_cursor(path, "s=1")
            self.assertEqual(ka.read_cursor(path), "s=1")
            self.assertFalse(os.path.exists(path + ".tmp"))


class FakeResponse:
    def __init__(self, status):
        self.status = status

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False


class NotifierTest(unittest.TestCase):
    def test_posts_json_with_bearer_token(self):
        seen = []

        def opener(request, timeout):
            seen.append(request)
            return FakeResponse(200)

        n = ka.Notifier("http://127.0.0.1:2586", "alerts", "tk_x", opener=opener)
        self.assertTrue(n.send("title é", "body", 4, ["warning"]))
        req = seen[0]
        self.assertEqual(req.get_header("Authorization"), "Bearer tk_x")
        self.assertEqual(
            json.loads(req.data),
            {"topic": "alerts", "title": "title é", "message": "body", "priority": 4, "tags": ["warning"]},
        )

    def test_failure_returns_false_after_one_attempt(self):
        calls = []

        def opener(request, timeout):
            calls.append(1)
            raise urllib.error.URLError("refused")

        n = ka.Notifier("http://127.0.0.1:1", "t", "k", opener=opener)
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertFalse(n.send("a", "b", 3, []))
        self.assertEqual(len(calls), 1)

    def test_server_error_status_returns_false(self):
        n = ka.Notifier("http://127.0.0.1:1", "t", "k", opener=lambda request, timeout: FakeResponse(503))
        with contextlib.redirect_stderr(io.StringIO()):
            self.assertFalse(n.send("a", "b", 3, []))


class BatcherTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.now = [0.0]
        self.sent = []
        self.accept = [True]
        test = self

        class Notifier:
            def send(self, *a):
                test.sent.append(a)
                return test.accept[0]

        args = type("A", (), {"watched": WATCHED, "window": 15, "host": "minipc",
                              "cursor_file": os.path.join(self.dir.name, "cursor")})()
        self.b = ka.Batcher(args, Notifier(), "c0", clock=lambda: self.now[0])

    def tearDown(self):
        self.dir.cleanup()

    def saved(self):
        return ka.read_cursor(self.b.args.cursor_file)

    def line(self, cursor, message=EARLYOOM_BUN):
        return json.dumps({"SYSLOG_IDENTIFIER": "earlyoom", "MESSAGE": message, "__CURSOR": cursor})

    def test_burst_sent_once_after_window_then_cursor_saved(self):
        self.b.feed(self.line("c1"))
        self.b.feed(self.line("c2"))
        self.b.tick()
        self.assertEqual(self.sent, [])
        self.assertIsNone(self.saved())
        self.now[0] = 15
        self.b.tick()
        self.assertEqual(len(self.sent), 1)
        self.assertEqual(self.sent[0][0], "minipc: 2 kill/crash events")
        self.assertEqual(self.saved(), "c2")

    def test_cursor_stays_before_unsent_event(self):
        self.b.feed(self.line("c1"))
        self.b.feed(json.dumps({"MESSAGE": "noise", "__CURSOR": "c2"}))
        self.b.tick()
        self.assertIsNone(self.saved())
        self.assertEqual(self.b.safe_cursor(), "c0")

    def test_failed_send_keeps_event_and_cursor(self):
        self.accept[0] = False
        self.b.feed(self.line("c1"))
        self.now[0] = 15
        self.b.tick()
        self.assertEqual(len(self.sent), 1)
        self.assertEqual(len(self.b.pending), 1)
        self.assertIsNone(self.saved())
        self.assertEqual(self.b.safe_cursor(), "c0")

    def test_failed_send_is_retried_with_growing_delay_then_cleared(self):
        self.accept[0] = False
        self.b.feed(self.line("c1"))
        self.now[0] = 15
        self.b.tick()
        self.now[0] = 16
        self.b.tick()
        self.assertEqual(len(self.sent), 1)
        self.now[0] = 17
        self.b.tick()
        self.assertEqual(len(self.sent), 2)
        self.now[0] = 20
        self.b.tick()
        self.assertEqual(len(self.sent), 2)
        self.now[0] = 21
        self.accept[0] = True
        self.b.tick()
        self.assertEqual(len(self.sent), 3)
        self.assertEqual(len(self.b.pending), 0)
        self.assertEqual(self.saved(), "c1")

    def test_events_during_outage_are_sent_together_with_the_old_one(self):
        self.accept[0] = False
        self.b.feed(self.line("c1"))
        self.now[0] = 15
        self.b.tick()
        self.b.feed(self.line("c2"))
        self.accept[0] = True
        self.now[0] = 17
        self.b.tick()
        self.assertEqual(self.sent[-1][0], "minipc: 2 kill/crash events")
        self.assertEqual(self.saved(), "c2")

    def test_steady_stream_still_saves_cursor_up_to_oldest_unsent(self):
        self.accept[0] = False
        for i in range(1, 6):
            self.now[0] = 15 * i
            self.b.feed(self.line(f"c{i}"))
            self.b.tick()
        self.assertEqual(self.b.safe_cursor(), "c0")
        self.accept[0] = True
        self.now[0] = 1000
        self.b.tick()
        self.assertEqual(self.saved(), "c5")

    def test_events_after_a_flush_start_a_new_window(self):
        self.b.feed(self.line("c1"))
        self.now[0] = 15
        self.b.tick()
        self.b.feed(self.line("c2"))
        self.now[0] = 16
        self.b.tick()
        self.assertEqual(len(self.sent), 1)
        self.now[0] = 31
        self.b.tick()
        self.assertEqual(len(self.sent), 2)

    def test_queue_is_bounded_and_cursor_follows_the_oldest_kept_event(self):
        self.accept[0] = False
        with contextlib.redirect_stderr(io.StringIO()) as err:
            for i in range(1, ka.MAX_PENDING + 3):
                self.b.feed(self.line(f"c{i}"))
        self.assertEqual(len(self.b.pending), ka.MAX_PENDING)
        self.assertEqual(self.b.safe_cursor(), "c2")
        self.assertIn("dropped the oldest", err.getvalue())

    def test_non_events_still_advance_cursor(self):
        self.b.feed(json.dumps({"MESSAGE": "noise", "__CURSOR": "c9"}))
        self.b.tick()
        self.assertEqual(self.sent, [])
        self.assertEqual(self.saved(), "c9")

    def test_bad_and_blank_lines_skipped(self):
        with contextlib.redirect_stderr(io.StringIO()):
            self.b.feed("")
            self.b.feed("{not json")
        self.b.tick()
        self.assertEqual(self.sent, [])

    def test_byte_list_message(self):
        raw = list(EARLYOOM_BUN.encode()) + [0xFF]
        e = ka.classify({"SYSLOG_IDENTIFIER": "earlyoom", "MESSAGE": raw}, WATCHED)
        self.assertEqual(e.title, "earlyoom killed bun")


class StopAndReviveTest(unittest.TestCase):
    def test_manual_restart_of_watched_unit(self):
        e = ka.classify(user_unit(ka.MSG_UNIT_STOPPED, JOB_TYPE="restart"), WATCHED)
        self.assertEqual(e.title, "herdr.service (user) restarted")
        self.assertEqual(e.priority, 3)

    def test_manual_stop_of_watched_unit(self):
        e = ka.classify(user_unit(ka.MSG_UNIT_STOPPED, JOB_TYPE="stop"), WATCHED)
        self.assertEqual(e.title, "herdr.service (user) stopped")

    def test_stop_of_unwatched_unit_ignored(self):
        self.assertIsNone(ka.classify(user_unit(ka.MSG_UNIT_STOPPED, unit="foo.service", JOB_TYPE="stop"), WATCHED))

    def revive(self, priority, message):
        return ka.classify({"SYSLOG_IDENTIFIER": "agent-revive", "PRIORITY": priority, "MESSAGE": message}, WATCHED)

    def test_relaunch_notice_sent(self):
        e = self.revive("5", "relaunched claude chat in pane wF:p1\nsession 8399, killed by earlyoom")
        self.assertEqual(e.title, "relaunched claude chat in pane wF:p1")
        self.assertEqual(e.body, "session 8399, killed by earlyoom")
        self.assertEqual(e.priority, 3)

    def test_revive_error_is_urgent(self):
        e = self.revive("3", "gave up relaunching claude in pane wF:p1")
        self.assertEqual(e.priority, 4)
        self.assertEqual(e.body, "")

    def test_revive_info_and_debug_not_sent(self):
        self.assertIsNone(self.revive("6", "tracking 3 agent panes"))
        self.assertIsNone(self.revive("7", "refresh"))

    def test_filters_cover_every_source(self):
        f = ka.journal_filters()
        for needle in ["MESSAGE_ID=" + ka.MSG_UNIT_STOPPED, "SYSLOG_IDENTIFIER=agent-revive",
                       "SYSLOG_IDENTIFIER=earlyoom", "_TRANSPORT=kernel"]:
            self.assertIn(needle, f)
        self.assertNotIn("+", [f[0], f[-1]])


if __name__ == "__main__":
    unittest.main()
