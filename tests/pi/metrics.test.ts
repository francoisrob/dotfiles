// Unit tests for extensions/metrics/metrics.ts, on session entries shaped like pi writes them.
import { describe, expect, test } from "bun:test";
import { join } from "node:path";
import { CONFIG_DIR } from "./lib/paths";

const m = await import(join(CONFIG_DIR, "extensions/metrics/metrics.ts"));

const T0 = Date.parse("2026-10-18T10:00:00.000Z");
const at = (s: number) => new Date(T0 + s * 1000).toISOString();
let n = 0;
const entry = (s: number, message: Record<string, unknown>) => ({ type: "message", id: `e${++n}`, parentId: null, timestamp: at(s), message });
const user = (s: number, content: unknown) => entry(s, { role: "user", content, timestamp: T0 + s * 1000 });
const usage = (input: number, output: number, cacheRead = 0, cacheWrite = 0, cost = 0) => ({
	input, output, cacheRead, cacheWrite, totalTokens: input + output + cacheRead + cacheWrite,
	cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: cost },
});
const assistant = (s: number, u: unknown, opts: { tools?: number; stopReason?: string } = {}) => entry(s, {
	role: "assistant",
	content: [{ type: "text", text: "ok" }, ...Array.from({ length: opts.tools ?? 0 }, (_, i) => ({ type: "toolCall", id: `t${i}`, name: "bash", arguments: {} }))],
	usage: u,
	stopReason: opts.stopReason ?? (opts.tools ? "toolUse" : "stop"),
	timestamp: T0 + s * 1000,
});
const toolResult = (s: number, u?: unknown) => entry(s, { role: "toolResult", toolCallId: "t0", toolName: "bash", content: [], isError: false, ...(u ? { usage: u } : {}), timestamp: T0 + s * 1000 });

describe("collectRuns: one run per user message", () => {
	test("no entries means no runs", () => {
		expect(m.collectRuns([])).toEqual([]);
	});

	test("entries before the first user message (system prompt, model change) are not a run", () => {
		const runs = m.collectRuns([
			entry(0, { role: "system", content: "", timestamp: T0 }),
			{ type: "model_change", id: "x", parentId: null, timestamp: at(0), provider: "xai", modelId: "grok-4.7" },
			{ type: "usage", id: "u", parentId: null, timestamp: at(0), kind: "cache_warm", usage: usage(5, 5) },
		]);
		expect(runs).toEqual([]);
	});

	test("a run adds up every model call, tool call and token until the next user message", () => {
		const runs = m.collectRuns([
			user(0, "fix the bug"),
			assistant(2, usage(1000, 100, 500, 0, 0.01), { tools: 2 }),
			toolResult(3),
			toolResult(4),
			assistant(9, usage(2000, 200, 1500, 100, 0.02), { tools: 1 }),
			toolResult(10),
			assistant(15, usage(3000, 50, 3000, 0, 0.005)),
			user(60, "thanks"),
			assistant(62, usage(10, 1, 0, 0, 0.001)),
		]);
		expect(runs).toHaveLength(2);
		const [a, b] = runs;
		expect(a.prompt).toBe("fix the bug");
		expect(a.calls).toBe(3);
		expect(a.toolCalls).toBe(3);
		expect({ ...a.usage, cost: 0 }).toEqual({ input: 6000, output: 350, cacheRead: 5000, cacheWrite: 100, cost: 0 });
		expect(a.usage.cost).toBeCloseTo(0.035, 9);
		expect(a.start).toBe(T0);
		expect(a.end).toBe(T0 + 15_000);
		expect(a.errors).toBe(0);
		expect(b.prompt).toBe("thanks");
		expect(b.calls).toBe(1);
		expect(b.end - b.start).toBe(2000);
	});

	test("nested usage on tool results, compaction and usage entries counts toward the run they happen in", () => {
		const [run] = m.collectRuns([
			user(0, "go"),
			assistant(1, usage(100, 10, 0, 0, 0.1), { tools: 1 }),
			toolResult(2, usage(50, 5, 0, 0, 0.05)),
			{ type: "compaction", id: "c", parentId: null, timestamp: at(3), summary: "s", firstKeptEntryId: "c", tokensBefore: 1, usage: usage(20, 2, 0, 0, 0.02) },
			{ type: "branch_summary", id: "b", parentId: null, timestamp: at(4), fromId: "x", summary: "s", usage: usage(1, 1, 0, 0, 0.001) },
			{ type: "usage", id: "u", parentId: null, timestamp: at(5), kind: "cache_warm", usage: usage(0, 0, 30, 0, 0.003) },
		]);
		expect({ ...run.usage, cost: 0 }).toEqual({ input: 171, output: 18, cacheRead: 30, cacheWrite: 0, cost: 0 });
		expect(run.usage.cost).toBeCloseTo(0.174, 9);
		expect(run.calls).toBe(1);
		expect(run.end).toBe(T0 + 5000);
	});

	test("errored and aborted model calls are counted, and missing usage does not crash", () => {
		const [run] = m.collectRuns([
			user(0, "go"),
			assistant(1, undefined, { stopReason: "error" }),
			assistant(2, { input: 5 }, { stopReason: "aborted" }),
		]);
		expect(run.calls).toBe(2);
		expect(run.errors).toBe(2);
		expect(run.usage).toEqual({ input: 5, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0 });
	});

	test("the prompt is the first non-empty line of text; images alone read as [image]", () => {
		const runs = m.collectRuns([
			user(0, "\n\n  first line  \nsecond line"),
			user(1, [{ type: "image", data: "", mimeType: "image/png" }, { type: "text", text: "look at this" }]),
			user(2, [{ type: "image", data: "", mimeType: "image/png" }]),
			user(3, ""),
		]);
		expect(runs.map((r: any) => r.prompt)).toEqual(["first line", "look at this", "[image]", ""]);
	});

	test("bash (!) entries and custom messages do not start a run", () => {
		const runs = m.collectRuns([
			user(0, "go"),
			entry(1, { role: "bashExecution", command: "ls", output: "", exitCode: 0, timestamp: T0 + 1000 }),
			entry(2, { role: "custom", customType: "x", content: "", display: true, timestamp: T0 + 2000 }),
			assistant(3, usage(1, 1)),
		]);
		expect(runs).toHaveLength(1);
		expect(runs[0].calls).toBe(1);
	});

	test("an unreadable timestamp gives an unknown time, not a crash or a negative time", () => {
		const bad = { ...user(0, "go"), timestamp: "not a date" };
		const [run] = m.collectRuns([bad, assistant(1, usage(1, 1))]);
		expect(m.formatDuration(run.end - run.start)).toBe("?");
	});
});

describe("cacheHit", () => {
	test("is cached input over all input across the run, as a percentage", () => {
		expect(m.cacheHit({ input: 250, output: 999, cacheRead: 700, cacheWrite: 50, cost: 0 })).toBe(70);
	});
	test("is undefined when nothing was sent", () => {
		expect(m.cacheHit({ input: 0, output: 5, cacheRead: 0, cacheWrite: 0, cost: 0 })).toBeUndefined();
	});
});

describe("formatTokens matches pi's own footer", () => {
	for (const [value, text] of [[0, "0"], [999, "999"], [1000, "1.0k"], [1450, "1.4k"], [9999, "10.0k"], [10_000, "10k"], [999_499, "999k"], [1_000_000, "1.0M"], [12_000_000, "12M"]] as const) {
		test(`${value} -> ${text}`, () => expect(m.formatTokens(value)).toBe(text));
	}
});

describe("formatDuration", () => {
	for (const [ms, text] of [[0, "0s"], [999, "0s"], [59_999, "59s"], [60_000, "1m 00s"], [65_000, "1m 05s"], [3_599_000, "59m 59s"], [3_600_000, "1h 00m"], [7_380_000, "2h 03m"], [-1, "?"], [Number.NaN, "?"], [Number.POSITIVE_INFINITY, "?"]] as const) {
		test(`${ms} -> ${text}`, () => expect(m.formatDuration(ms)).toBe(text));
	}
});

describe("formatCost", () => {
	test("three decimals like pi's footer, more for tiny amounts so they do not read as free", () => {
		expect(m.formatCost(0)).toBe("$0.000");
		expect(m.formatCost(0.0314)).toBe("$0.031");
		expect(m.formatCost(1.5)).toBe("$1.500");
		expect(m.formatCost(0.00042)).toBe("$0.0004");
	});
});

const run = (over: Record<string, unknown> = {}) => ({
	prompt: "go", start: T0, end: T0 + 23_000, calls: 4, toolCalls: 7, errors: 0,
	usage: { input: 12_000, output: 1400, cacheRead: 30_000, cacheWrite: 0, cost: 0.0314 }, ...over,
});

describe("runSummary: the footer's last-run part", () => {
	test("a finished run shows time first, then tokens in/out/cached with the cache hit, cost, calls and tool calls", () => {
		expect(m.runSummary(run(), { live: false })).toBe("last run 23s · 12k in · 1.4k out · 30k cached (71%) · $0.031 · 4 model calls · 7 tool calls");
	});
	test("singular words for one call and one tool call", () => {
		expect(m.runSummary(run({ calls: 1, toolCalls: 1 }), { live: false })).toMatch(/ · 1 model call · 1 tool call$/);
	});
	test("no cache-hit figure when nothing was sent yet, and failed calls are called out", () => {
		const s = m.runSummary(run({ errors: 2, usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0 } }), { live: false });
		expect(s).toContain("0 cached · ");
		expect(s).not.toContain("%");
		expect(s).toMatch(/ · 2 failed$/);
	});
	test("a live run counts time up to now and says it is running", () => {
		expect(m.runSummary(run(), { live: true, now: T0 + 65_000 })).toMatch(/^running 1m 05s · 12k in · /);
	});
	test("no runs yet reads as a plain hint", () => {
		expect(m.runSummary(undefined, { live: false })).toBe("last run: none yet");
	});
});

describe("contextSummary: the footer's context part", () => {
	const compaction = { enabled: true, reserveTokens: 32_768 };
	test("tokens used of the window, the percentage, and where auto-compaction starts", () => {
		expect(m.contextSummary({ tokens: 38_000, contextWindow: 200_000, percent: 19 }, compaction)).toBe("context 38k/200k (19%), compacts at 167k");
	});
	test("unknown right after a compaction, until the next reply", () => {
		expect(m.contextSummary({ tokens: null, contextWindow: 200_000, percent: null }, compaction)).toBe("context ?/200k (known after the next reply), compacts at 167k");
	});
	test("says so when auto-compaction is off", () => {
		expect(m.contextSummary({ tokens: 1000, contextWindow: 200_000, percent: 0.5 }, { enabled: false, reserveTokens: 1 })).toBe("context 1.0k/200k (1%), auto-compact off");
	});
	test("a reserve larger than the window means compaction starts at once, never a negative number", () => {
		expect(m.contextSummary({ tokens: 10, contextWindow: 1000, percent: 1 }, { enabled: true, reserveTokens: 5000 })).toContain("compacts at 0");
	});
	test("no model yet", () => {
		expect(m.contextSummary(undefined, compaction)).toBe("context: no model");
	});
});

describe("usageTable: what /usage shows", () => {
	test("one row per run, newest last, with a total row", () => {
		const lines: string[] = m.usageTable([run({ prompt: "first" }), run({ prompt: "second", calls: 1, toolCalls: 0 })]);
		expect(lines[0]).toMatch(/^#\s+in\s+out\s+cached\s+cost\s+hit\s+calls\s+tools\s+time\s+message$/);
		expect(lines[1]).toMatch(/^1\s+12k\s+1\.4k\s+30k\s+\$0\.031\s+71%\s+4\s+7\s+23s\s+first$/);
		expect(lines[2]).toMatch(/^2\s.*\ssecond$/);
		expect(lines.at(-1)).toMatch(/^total\s+24k\s+2\.8k\s+60k\s+\$0\.063\s+71%\s+5\s+7\s+46s$/);
	});
	test("an empty session says so", () => {
		expect(m.usageTable([])).toEqual(["No messages sent in this session yet."]);
	});
	test("columns line up whatever the widths of the numbers", () => {
		const lines: string[] = m.usageTable([run(), run({ usage: { input: 1, output: 1, cacheRead: 0, cacheWrite: 0, cost: 0 } })]);
		const msgCol = (l: string) => l.lastIndexOf(" go");
		expect(msgCol(lines[1])).toBe(msgCol(lines[2]));
	});
});
