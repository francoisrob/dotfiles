// Splits a pi session into runs (one per user message) and formats their usage.
// No pi imports, so it is unit-tested on plain session entries.

export type Usage = { input: number; output: number; cacheRead: number; cacheWrite: number; cost: number };

export type Run = {
	/** First non-empty line of the message that started the run. */
	prompt: string;
	/** Epoch ms of that message, and of the last entry in the run. NaN when unreadable. */
	start: number;
	end: number;
	/** Model calls (assistant messages), and how many of them errored or were aborted. */
	calls: number;
	errors: number;
	/** Tool calls the model asked for. */
	toolCalls: number;
	usage: Usage;
};

export type ContextUsage = { tokens: number | null; contextWindow: number; percent: number | null };
export type CompactionSettings = { enabled: boolean; reserveTokens: number };

// Session entries as pi writes them (docs/session-format.md). Only the fields read here.
type RawUsage = { input?: number; output?: number; cacheRead?: number; cacheWrite?: number; cost?: { total?: number } };
type Block = { type: string; text?: string };
type Entry = {
	type: string;
	timestamp?: string;
	usage?: RawUsage;
	message?: { role: string; content?: string | Block[]; usage?: RawUsage; stopReason?: string };
};

const emptyUsage = (): Usage => ({ input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0 });

function add(total: Usage, u: RawUsage | undefined) {
	if (!u) return;
	total.input += u.input ?? 0;
	total.output += u.output ?? 0;
	total.cacheRead += u.cacheRead ?? 0;
	total.cacheWrite += u.cacheWrite ?? 0;
	total.cost += u.cost?.total ?? 0;
}

function promptText(content: string | Block[] | undefined): string {
	const text = typeof content === "string" ? content : (content ?? []).filter((b) => b.type === "text").map((b) => b.text ?? "").join("\n");
	const line = text.split("\n").map((l) => l.trim()).find(Boolean);
	if (line) return line;
	return Array.isArray(content) && content.some((b) => b.type === "image") ? "[image]" : "";
}

/** One run per user message, in order. Entries before the first user message belong to no run. */
export function collectRuns(entries: readonly Entry[]): Run[] {
	const runs: Run[] = [];
	let run: Run | undefined;
	for (const e of entries) {
		const time = e.timestamp ? Date.parse(e.timestamp) : Number.NaN;
		const msg = e.type === "message" ? e.message : undefined;
		if (msg?.role === "user") {
			run = { prompt: promptText(msg.content), start: time, end: time, calls: 0, errors: 0, toolCalls: 0, usage: emptyUsage() };
			runs.push(run);
			continue;
		}
		if (!run) continue;
		if (msg?.role === "assistant") {
			run.calls++;
			if (msg.stopReason === "error" || msg.stopReason === "aborted") run.errors++;
			if (Array.isArray(msg.content)) run.toolCalls += msg.content.filter((b) => b.type === "toolCall").length;
			add(run.usage, msg.usage);
		} else if (msg?.role === "toolResult") {
			add(run.usage, msg.usage);
		} else if (e.type === "usage" || e.type === "compaction" || e.type === "branch_summary") {
			add(run.usage, e.usage);
		}
		run.end = time;
	}
	return runs;
}

/** Share of the input that came from the prompt cache, in percent. */
export function cacheHit(u: Usage): number | undefined {
	const sent = u.input + u.cacheRead + u.cacheWrite;
	return sent > 0 ? (u.cacheRead / sent) * 100 : undefined;
}

/** Same thresholds as pi's own footer, so the two never disagree. */
export function formatTokens(count: number): string {
	if (count < 1000) return count.toString();
	if (count < 10_000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1_000_000) return `${Math.round(count / 1000)}k`;
	if (count < 10_000_000) return `${(count / 1_000_000).toFixed(1)}M`;
	return `${Math.round(count / 1_000_000)}M`;
}

export function formatDuration(ms: number): string {
	if (!Number.isFinite(ms) || ms < 0) return "?";
	const s = Math.floor(ms / 1000);
	const pad = (v: number) => String(v).padStart(2, "0");
	if (s < 60) return `${s}s`;
	if (s < 3600) return `${Math.floor(s / 60)}m ${pad(s % 60)}s`;
	return `${Math.floor(s / 3600)}h ${pad(Math.floor((s % 3600) / 60))}m`;
}

export function formatCost(cost: number): string {
	return cost > 0 && cost < 0.001 ? `$${cost.toFixed(4)}` : `$${cost.toFixed(3)}`;
}

const plural = (n: number, word: string) => `${n} ${word}${n === 1 ? "" : "s"}`;

export function runSummary(run: Run | undefined, opts: { live: boolean; now?: number }): string {
	if (!run) return "last run: none yet";
	const u = run.usage;
	const hit = cacheHit(u);
	// Time first: pi cuts the footer at the terminal width, so the most useful parts lead.
	const time = formatDuration((opts.live ? (opts.now ?? Date.now()) : run.end) - run.start);
	const parts = [
		opts.live ? `running ${time}` : `last run ${time}`,
		`${formatTokens(u.input)} in`,
		`${formatTokens(u.output)} out`,
		hit === undefined ? `${formatTokens(u.cacheRead)} cached` : `${formatTokens(u.cacheRead)} cached (${Math.round(hit)}%)`,
		formatCost(u.cost),
		plural(run.calls, "model call"),
		plural(run.toolCalls, "tool call"),
		...(run.errors ? [`${run.errors} failed`] : []),
	];
	return parts.join(" · ");
}

export function contextSummary(ctx: ContextUsage | undefined, compaction: CompactionSettings): string {
	if (!ctx) return "context: no model";
	const window = formatTokens(ctx.contextWindow);
	const used = ctx.tokens === null || ctx.percent === null
		? `context ?/${window} (known after the next reply)`
		: `context ${formatTokens(ctx.tokens)}/${window} (${Math.round(ctx.percent)}%)`;
	// pi compacts once the context passes contextWindow - reserveTokens (shouldCompact in pi).
	const when = compaction.enabled ? `compacts at ${formatTokens(Math.max(0, ctx.contextWindow - compaction.reserveTokens))}` : "auto-compact off";
	return `${used}, ${when}`;
}

/** Plain-text table for /usage: header, one row per run, then the total. */
export function usageTable(runs: readonly Run[]): string[] {
	if (runs.length === 0) return ["No messages sent in this session yet."];
	const total: Run = { prompt: "", start: 0, end: 0, calls: 0, errors: 0, toolCalls: 0, usage: emptyUsage() };
	let time = 0;
	const row = (label: string, r: Run, ms: number) => {
		const hit = cacheHit(r.usage);
		return [label, formatTokens(r.usage.input), formatTokens(r.usage.output), formatTokens(r.usage.cacheRead), formatCost(r.usage.cost),
			hit === undefined ? "-" : `${Math.round(hit)}%`, String(r.calls), String(r.toolCalls), formatDuration(ms)];
	};
	const rows = runs.map((r, i) => {
		const ms = r.end - r.start;
		if (Number.isFinite(ms) && ms >= 0) time += ms;
		total.calls += r.calls;
		total.toolCalls += r.toolCalls;
		add(total.usage, { ...r.usage, cost: { total: r.usage.cost } });
		return [...row(String(i + 1), r, ms), r.prompt];
	});
	const table = [["#", "in", "out", "cached", "cost", "hit", "calls", "tools", "time", "message"], ...rows, [...row("total", total, time), ""]];
	const widths = table[0].map((_, c) => Math.max(...table.map((r) => r[c].length)));
	return table.map((r) => r.map((cell, c) => (c === r.length - 1 ? cell : cell.padEnd(widths[c]))).join("  ").trimEnd());
}
