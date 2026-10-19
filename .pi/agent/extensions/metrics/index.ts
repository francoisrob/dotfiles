// Footer line with context and last-run usage (live while pi works), and /usage per message.
// Numbers are read from the session entries, so they survive /resume and /tree.
import { type ExtensionAPI, type ExtensionContext, SettingsManager } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth } from "@earendil-works/pi-tui";
import { collectRuns, contextSummary, formatDuration, runSummary, usageTable } from "./metrics.ts";

const STATUS_KEY = "metrics";
const TICK_MS = 1000;

export default function (pi: ExtensionAPI) {
	let timer: ReturnType<typeof setInterval> | undefined;
	let running = false;
	/** When pi got the latest user message; the run it starts is saved just after. */
	let sentAt = Number.NaN;

	const stopTimer = () => {
		if (timer) clearInterval(timer);
		timer = undefined;
	};

	function status(ctx: ExtensionContext): string {
		// pi's own resolver: model override, then the setting, then pi's default.
		const compaction = SettingsManager.inMemory(pi.getSettings()).getCompactionSettings(ctx.model);
		const runs = collectRuns(ctx.sessionManager.getBranch());
		const last = runs.at(-1);
		let run: string;
		if (!running) run = runSummary(last, { live: false });
		else if (last && last.start >= sentAt) run = runSummary(last, { live: true });
		else run = `running ${formatDuration(Date.now() - sentAt)} · starting`;
		return `${contextSummary(ctx.getContextUsage(), compaction)} │ ${run}`;
	}

	const refresh = (_event: unknown, ctx: ExtensionContext) => {
		if (ctx.mode !== "tui") return;
		ctx.ui.setStatus(STATUS_KEY, status(ctx));
	};

	pi.on("session_start", refresh);
	pi.on("session_tree", refresh);
	pi.on("session_compact", refresh);
	pi.on("message_end", refresh);
	pi.on("turn_end", refresh);
	pi.on("tool_execution_end", refresh);

	pi.on("before_agent_start", (event, _ctx) => {
		// Entry timestamps have millisecond precision; allow for the same millisecond.
		if (event.messageType === "user") sentAt = Date.now() - 1;
	});

	pi.on("agent_start", (_event, ctx) => {
		if (ctx.mode !== "tui") return;
		running = true;
		if (Number.isNaN(sentAt)) sentAt = Date.now() - 1;
		stopTimer();
		timer = setInterval(() => refresh(undefined, ctx), TICK_MS);
	});

	const finish = (_event: unknown, ctx: ExtensionContext) => {
		running = false;
		stopTimer();
		refresh(undefined, ctx);
	};
	pi.on("agent_end", finish);
	pi.on("agent_settled", finish);

	pi.on("session_shutdown", (_event, ctx) => {
		running = false;
		stopTimer();
		if (ctx.mode === "tui") ctx.ui.setStatus(STATUS_KEY, undefined);
	});

	pi.registerCommand("usage", {
		description: "Token usage, cost and time for each message in this session",
		handler: async (_args, ctx) => {
			const lines = usageTable(collectRuns(ctx.sessionManager.getBranch()));
			if (ctx.mode !== "tui") {
				ctx.ui.notify(lines.join("\n"), "info");
				return;
			}
			await ctx.ui.custom<void>((_tui, theme, _keybindings, done) => ({
				render: (width: number) =>
					[
						theme.fg("accent", "Usage per message (Esc to close)"),
						"",
						...lines.map((l, i) => (i === 0 || l.startsWith("total") ? theme.bold(l) : l)),
					].map((l) => truncateToWidth(l, width)),
				handleInput: (data: string) => {
					if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c") || matchesKey(data, "enter")) done();
				},
				invalidate: () => {},
			}));
		},
	});
}
