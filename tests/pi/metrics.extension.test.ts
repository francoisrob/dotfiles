// Wiring tests for extensions/metrics/index.ts against a recording stand-in for pi's API.
// The pi modules it imports are mapped to the installed pi, which bun cannot resolve from here.
import { afterEach, describe, expect, mock, test } from "bun:test";
import { dirname, join } from "node:path";
import { CONFIG_DIR, piPackageDir } from "./lib/paths";

const piDir = piPackageDir();
const realPi = await import(join(piDir, "dist/index.js"));
const realTui = await import(join(dirname(piDir), "pi-tui/dist/index.js"));
mock.module("@earendil-works/pi-coding-agent", () => realPi);
mock.module("@earendil-works/pi-tui", () => realTui);
const extension = (await import(join(CONFIG_DIR, "extensions/metrics/index.ts"))).default;

type Handler = (event: any, ctx: any) => unknown;
const T0 = Date.now();
const iso = (ms: number) => new Date(ms).toISOString();

function setup(opts: { mode?: string; settings?: Record<string, unknown>; model?: { provider: string; id: string } } = {}) {
	const handlers = new Map<string, Handler[]>();
	const commands = new Map<string, any>();
	const statuses: Array<string | undefined> = [];
	const notes: string[] = [];
	const customs: any[] = [];
	const entries: any[] = [];
	const pi = {
		on: (name: string, h: Handler) => {
			handlers.set(name, [...(handlers.get(name) ?? []), h]);
			return () => {};
		},
		registerCommand: (name: string, options: any) => commands.set(name, options),
		getSettings: () => opts.settings ?? { compaction: { enabled: true, reserveTokens: 32_768 } },
	};
	const ctx = {
		mode: opts.mode ?? "tui",
		hasUI: (opts.mode ?? "tui") !== "print",
		model: opts.model ?? { provider: "example", id: "model-a" },
		sessionManager: { getBranch: () => entries },
		getContextUsage: () => ({ tokens: 38_000, contextWindow: 200_000, percent: 19 }),
		ui: {
			setStatus: (key: string, text: string | undefined) => {
				expect(key).toBe("metrics");
				statuses.push(text);
			},
			notify: (msg: string) => notes.push(msg),
			custom: async (factory: any) => {
				const component = factory({ requestRender() {} }, realTheme(), {}, () => customs.push("closed"));
				customs.push(component);
			},
		},
	};
	extension(pi);
	const emit = async (name: string, event: Record<string, unknown> = {}) => {
		for (const h of handlers.get(name) ?? []) expect(await h({ type: name, ...event }, ctx)).toBeUndefined();
	};
	return { handlers, commands, statuses, notes, customs, entries, ctx, emit };
}

// A theme whose colours are no-ops, so rendered lines can be compared as plain text.
function realTheme() {
	return { fg: (_c: string, s: string) => s, bold: (s: string) => s };
}

const cleanups: Array<() => Promise<void>> = [];
afterEach(async () => {
	for (const c of cleanups.splice(0)) await c();
});
const tracked = (s: ReturnType<typeof setup>) => {
	cleanups.push(() => s.emit("session_shutdown"));
	return s;
};

const userEntry = (ms: number, text: string) => ({ type: "message", id: `u${ms}`, parentId: null, timestamp: iso(ms), message: { role: "user", content: text, timestamp: ms } });
const assistantEntry = (ms: number, cost: number) => ({
	type: "message", id: `a${ms}`, parentId: null, timestamp: iso(ms),
	message: { role: "assistant", content: [{ type: "toolCall", id: "t", name: "bash", arguments: {} }], stopReason: "toolUse", timestamp: ms,
		usage: { input: 12_000, output: 1400, cacheRead: 30_000, cacheWrite: 0, totalTokens: 43_400, cost: { total: cost } } },
});

describe("registration", () => {
	test("registers /usage with a description, and refresh handlers for the run and session events", () => {
		const s = setup();
		expect(s.commands.get("usage")?.description).toMatch(/usage/i);
		for (const name of ["session_start", "session_tree", "session_compact", "session_shutdown", "before_agent_start", "agent_start", "agent_end", "agent_settled", "message_end", "turn_end", "tool_execution_end"]) {
			expect(s.handlers.has(name), name).toBe(true);
		}
	});
});

describe("footer status", () => {
	test("on session start it shows context in tokens, where compaction starts, and the last run", async () => {
		const s = tracked(setup());
		s.entries.push(userEntry(T0 - 30_000, "fix it"), assistantEntry(T0 - 7_000, 0.0314));
		await s.emit("session_start", { reason: "startup" });
		expect(s.statuses.at(-1)).toBe("context 38k/200k (19%), compacts at 167k │ last run 23s · 12k in · 1.4k out · 30k cached (71%) · $0.031 · 1 model call · 1 tool call");
	});

	test("the text survives pi's status cleanup unchanged (pi turns tabs and newlines into spaces and collapses runs of spaces)", async () => {
		const s = tracked(setup());
		s.entries.push(userEntry(T0 - 30_000, "fix it"), assistantEntry(T0 - 7_000, 0.0314));
		await s.emit("session_start", { reason: "startup" });
		const text = s.statuses.at(-1) ?? "";
		expect(text).not.toMatch(/[\r\n\t]| {2}/);
		expect(text).toBe(text.trim());
	});

	test("compaction point follows the effective settings, including a per-model override, via pi's own resolver", async () => {
		const s = tracked(setup({ settings: { compaction: { enabled: true, reserveTokens: 32_768, modelOverrides: { "example/model-a": { reserveTokens: 50_000 } } } } }));
		await s.emit("session_start", { reason: "startup" });
		expect(s.statuses.at(-1)).toContain("compacts at 150k");
	});

	test("pi's built-in default applies when settings name no reserve", async () => {
		const s = tracked(setup({ settings: {} }));
		await s.emit("session_start", { reason: "startup" });
		const expected = 200_000 - realPi.DEFAULT_COMPACTION_SETTINGS.reserveTokens;
		expect(s.statuses.at(-1)).toContain(`compacts at ${Math.round(expected / 1000)}k`);
	});

	test("does nothing outside the interactive TUI (print, json, rpc): no status, no timer", async () => {
		const all = ["print", "json", "rpc"].map((mode) => ({ mode, s: tracked(setup({ mode })) }));
		for (const { s } of all) {
			await s.emit("session_start", { reason: "startup" });
			await s.emit("before_agent_start", { messageType: "user", prompt: "x" });
			await s.emit("agent_start");
		}
		await Bun.sleep(1200);
		for (const { mode, s } of all) expect(s.statuses, mode).toEqual([]);
	});
});

describe("live timer", () => {
	test("ticks every second while a run is going, without any pi event, and stops when pi settles", async () => {
		const s = tracked(setup());
		s.entries.push(userEntry(T0 - 90_000, "old"), assistantEntry(T0 - 80_000, 0.01));
		await s.emit("session_start", { reason: "startup" });
		await s.emit("before_agent_start", { messageType: "user", prompt: "new" });
		await s.emit("agent_start");
		const before = s.statuses.length;
		await Bun.sleep(1150);
		expect(s.statuses.length).toBeGreaterThan(before);
		await s.emit("agent_settled");
		const settled = s.statuses.length;
		expect(s.statuses.at(-1)).toMatch(/ │ last run \d+/);
		await Bun.sleep(1150);
		expect(s.statuses.length).toBe(settled);
	});

	test("before the new message is saved it says it is starting, and never shows the previous run as running", async () => {
		const s = tracked(setup());
		s.entries.push(userEntry(T0 - 300_000, "old"), assistantEntry(T0 - 290_000, 0.01));
		await s.emit("before_agent_start", { messageType: "user", prompt: "new" });
		await s.emit("agent_start");
		await s.emit("turn_end");
		expect(s.statuses.at(-1)).toMatch(/ │ running \d+s · starting$/);
		s.entries.push(userEntry(Date.now(), "new"));
		await s.emit("message_end", { message: { role: "user" } });
		expect(s.statuses.at(-1)).toMatch(/ │ running 0s · 0 in · /);
	});

	test("a second agent_start (retry) does not leave two timers running", async () => {
		const s = tracked(setup());
		await s.emit("before_agent_start", { messageType: "user", prompt: "x" });
		await s.emit("agent_start");
		await s.emit("agent_start");
		await s.emit("agent_end");
		const n = s.statuses.length;
		await Bun.sleep(1150);
		expect(s.statuses.length).toBe(n);
	});

	test("shutdown stops the timer and clears the status", async () => {
		const s = setup();
		await s.emit("session_start", { reason: "startup" });
		await s.emit("before_agent_start", { messageType: "user", prompt: "x" });
		await s.emit("agent_start");
		const shown = s.statuses.length;
		expect(s.statuses.at(-1)).toContain("context");
		await s.emit("session_shutdown");
		expect(s.statuses).toHaveLength(shown + 1);
		expect(s.statuses.at(-1)).toBeUndefined();
		const n = s.statuses.length;
		await Bun.sleep(1150);
		expect(s.statuses.length).toBe(n);
	});
});

describe("/usage", () => {
	test("in the TUI it opens a panel with the per-message table, never wider than the terminal, closed by Escape", async () => {
		const s = tracked(setup());
		s.entries.push(userEntry(T0 - 30_000, "fix it"), assistantEntry(T0 - 7_000, 0.0314));
		await s.commands.get("usage").handler("", s.ctx);
		const panel = s.customs[0];
		const lines: string[] = panel.render(100);
		expect(lines.join("\n")).toContain("fix it");
		expect(lines.some((l) => l.startsWith("total"))).toBe(true);
		for (const width of [100, 40, 1]) {
			for (const l of panel.render(width)) expect(realTui.visibleWidth(l)).toBeLessThanOrEqual(width);
		}
		panel.handleInput("x");
		expect(s.customs).toHaveLength(1);
		panel.handleInput("\x1b");
		expect(s.customs.at(-1)).toBe("closed");
	});

	test("without the TUI it prints the same table as a notice", async () => {
		const s = tracked(setup({ mode: "rpc" }));
		s.entries.push(userEntry(T0 - 30_000, "fix it"), assistantEntry(T0 - 7_000, 0.0314));
		await s.commands.get("usage").handler("", s.ctx);
		expect(s.notes[0]).toContain("fix it");
		expect(s.notes[0]).toMatch(/^#\s+in/);
	});
});
