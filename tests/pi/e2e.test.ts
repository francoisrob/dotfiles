// End-to-end: bare `pi` in a fish login shell against the real model (a few cents).
// Run with PI_E2E=1; PI_E2E_MODEL overrides the model.
import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { LOGIN_ENV } from "./lib/paths";
import { makeSandbox } from "./lib/sandbox";

const enabled = process.env.PI_E2E === "1";
const d = enabled ? describe : describe.skip;
const MODEL = process.env.PI_E2E_MODEL ? ["--model", process.env.PI_E2E_MODEL] : [];

let dir = "";
let cleanup = () => {};
beforeAll(() => {
	const sb = makeSandbox("e2e");
	dir = sb.dir;
	cleanup = sb.cleanup;
});
afterAll(() => cleanup());

const quote = (s: string) => `'${s.replaceAll("'", "\\'")}'`;

/** Run a bare `pi` inside a fish login shell. */
function fishPi(args: string[], sessionDir: string) {
	const line = ["pi", ...args.map(quote)].join(" ") + " < /dev/null";
	const proc = Bun.spawnSync(["fish", "--login", "-c", line], {
		cwd: dir,
		env: LOGIN_ENV,
		timeout: 240_000,
	});
	return { code: proc.exitCode, out: proc.stdout.toString(), err: proc.stderr.toString(), sessionDir };
}

function sessionMessages(sessionDir: string): any[] {
	const files = readdirSync(sessionDir).filter((f) => f.endsWith(".jsonl"));
	return files.flatMap((f) => readFileSync(join(sessionDir, f), "utf8").split("\n").filter(Boolean).map((l) => JSON.parse(l)));
}

d("pi end to end", () => {
	test("bare pi in fish runs a bash command, loads AGENTS.md, and answers", () => {
		const sessionDir = join(dir, "s1");
		const r = fishPi(["-p", "--no-extensions", ...MODEL, "--session-dir", sessionDir,
			"Run this bash command: echo pi-e2e-$((6*7)) . Then reply with two lines only: the command's output, and the first heading of your project instructions."], sessionDir);
		expect(r.code).toBe(0);
		expect(r.out).toContain("pi-e2e-42");
		expect(r.out).toContain("Global instructions");
	});

	test("a prompt template expands into the message the model receives", () => {
		const sessionDir = join(dir, "s2");
		const r = fishPi(["-p", "--no-extensions", "--no-tools", ...MODEL, "--session-dir", sessionDir,
			"/fix Ignore the request above. Reply with the single word: expanded"], sessionDir);
		expect(r.code).toBe(0);
		const user = sessionMessages(sessionDir).find((e) => e.message?.role === "user");
		const text = JSON.stringify(user?.message?.content ?? "");
		expect(text).toContain("Apply the minimal diff from your diagnosis.");
		expect(text).toContain('Follow the \\"Bug investigation\\" rules');
		expect(text).toContain("Reply with the single word: expanded");
	});

	test("the interactive TUI starts, answers, and quits cleanly", async () => {
		const session = `pi-e2e-${process.pid}`;
		const tmux = (...a: string[]) => Bun.spawnSync(["tmux", ...a]).stdout.toString();
		const screen = () => tmux("capture-pane", "-p", "-t", session);
		const waitFor = async (check: (s: string) => boolean, ms: number) => {
			const end = Date.now() + ms;
			while (Date.now() < end) {
				if (check(screen())) return true;
				await Bun.sleep(1000);
			}
			return false;
		};
		const busy = (s: string) => /Working|esc to interrupt|Retrying/.test(s);
		const sessionDir = join(dir, "s3");
		// Command as separate arguments, so tmux execs fish directly and no other shell
		// re-parses the quoting.
		tmux("new-session", "-d", "-s", session, "-x", "140", "-y", "40", "-c", dir,
			"fish", "--login", "-c", ["pi", ...MODEL, "--session-dir", sessionDir].map(quote).join(" "));
		try {
			// pi's footer shows the context gauge (for example "7.3%/200k") once it is ready.
			expect(await waitFor((s) => /\d+(\.\d+)?%\/\d+k/.test(s), 60_000)).toBe(true);
			tmux("send-keys", "-t", session, "-l", "Reply with the single word: pong");
			tmux("send-keys", "-t", session, "Enter");
			await waitFor(busy, 15_000);
			expect(await waitFor((s) => !busy(s) && /\bpong\b/i.test(s.split("Reply with the single word")[1] ?? ""), 120_000)).toBe(true);
			expect(screen()).not.toMatch(/Request timed out|Error:/);
			tmux("send-keys", "-t", session, "-l", "/quit");
			tmux("send-keys", "-t", session, "Enter");
			expect(await waitFor(() => !tmux("list-sessions").includes(session), 20_000)).toBe(true);
		} finally {
			Bun.spawnSync(["tmux", "kill-session", "-t", session]);
		}
	});
});
