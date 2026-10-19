// Mutation testing: apply one deliberate break at a time to a sandbox copy and expect the
// tests to fail. Hand-written because StrykerJS cannot mutate JSON or Markdown.
// Run: bun mutate.ts [ids...]
import { cpSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import { CONFIG_DIR, TESTS_DIR } from "./lib/paths";
import { makeSandbox } from "./lib/sandbox";

type Target = "AGENTS.md" | "settings.json" | "models.json" | "prompts/diagnose.md" | "prompts/fix.md";
type Mutant = { id: string; target: Target; what: string; apply: (text: string) => string; tests: string[] };

const CONFIG_TESTS = ["config.contract.test.ts", "integration.test.ts", "content.lint.test.ts"];

/** Replace exactly one occurrence, so a mutant whose anchor has gone stale fails loudly. */
const swap = (from: string, to: string) => (text: string) => {
	const at = text.indexOf(from);
	if (at === -1 || text.indexOf(from, at + 1) !== -1) throw new Error(`anchor not found exactly once: ${from}`);
	return text.slice(0, at) + to + text.slice(at + from.length);
};
const json = (edit: (o: any) => void) => (text: string) => {
	const o = JSON.parse(text);
	edit(o);
	return JSON.stringify(o, null, 2);
};
const dropLineWith = (needle: string) => (text: string) => {
	const lines = text.split("\n");
	const hits = lines.filter((l) => l.includes(needle));
	if (hits.length !== 1) throw new Error(`expected one line containing: ${needle}`);
	return lines.filter((l) => !l.includes(needle)).join("\n");
};

const config: Array<[Target, string, (t: string) => string]> = [
	["settings.json", "thinking level typo", json((o) => (o.defaultThinkingLevel = "mediun"))],
	["settings.json", "unknown key (typo of a real one)", json((o) => (o.defaultModell = "grok-4.7"))],
	["settings.json", "a tool that does not exist", json((o) => o.defaultTools.push("grepp"))],
	["settings.json", "analytics switched on", json((o) => (o.enableAnalytics = true))],
	["settings.json", "install telemetry switched on", json((o) => (o.enableInstallTelemetry = true))],
	["settings.json", "provider retries stacked on pi's", json((o) => (o.retry.provider.maxRetries = 2))],
	["settings.json", "npm update notifier back on", json((o) => (o.npmCommand = ["npm"]))],
	["settings.json", "default model not in the catalog", json((o) => (o.defaultModel = "grok-9"))],
	["settings.json", "compaction reserve larger than the window", json((o) => (o.compaction.reserveTokens = 190000))],
	["settings.json", "broken JSON", (t) => t.replace(/}\s*$/, "")],
	["models.json", "window above the price cliff", json((o) => (o.providers.xai.modelOverrides["grok-4.7"].contextWindow = 250000))],
	["models.json", "override for a model pi does not have", json((o) => (o.providers.xai.modelOverrides["grok-4.2"] = { contextWindow: 200000 }))],
	["models.json", "the cap for the default model removed", json((o) => delete o.providers.xai.modelOverrides["grok-4.7"])],
	["models.json", "broken JSON", (t) => t.replace(/}\s*$/, "")],
	["AGENTS.md", "an em dash in the text", swap("## Machine", `## Machine ${String.fromCharCode(0x2014)} setup`)],
	["AGENTS.md", "a gendered pronoun", swap("the owner wants to understand", "he wants to understand")],
	["AGENTS.md", "the result line tied to the test bench", swap("`<command>: <N> pass, <N> fail`", "`bun test: 1615 pass, 2 skip, 0 fail`")],
	["AGENTS.md", "the full-suite rule tied to bun", swap("full test command once (find it in the README, package.json scripts, Makefile or CI config)", "test command once (`bun test` here)")],
	["AGENTS.md", "the false README claim is back", swap("~/hub/tools/README.md explains them, and each tool's `<name>.tool.json` manifest beside its source lists its arguments. Read both before use.", "Each has a README next to its source; read it before use.")],
	["AGENTS.md", "a path that does not exist", swap("~/hub/tools/README.md", "~/hub/tools/READ-ME.md")],
	["AGENTS.md", "a duplicated line", (t) => t.replace("## Git and processes\n", "## Git and processes\n- Before starting a dev server, bot, or watcher, check `ps` for one already running.\n")],
	["AGENTS.md", "bloated past the word budget", (t) => `${t}\n${"- Be careful. ".repeat(60)}\n`],
	["AGENTS.md", "the section the prompts point to renamed", swap("## Bug investigation", "## Debugging")],
	["AGENTS.md", "a fixture name leaks in", swap("Projects live under ~/projects", "Projects (like Elysia) live under ~/projects")],
	["prompts/diagnose.md", "no $ARGUMENTS", swap("Diagnose: $ARGUMENTS", "Diagnose the reported bug.")],
	["prompts/diagnose.md", "restates an AGENTS.md rule", swap("3. Trace to the origin.", "3. Trace the bad value backward to where it originates and fix it there.")],
	["prompts/diagnose.md", "points to a section that does not exist", swap('the "Bug investigation" rules', 'the "Debugging" rules')],
	["prompts/diagnose.md", "frontmatter broken", swap("---\nDiagnose:", "Diagnose:")],
	["prompts/fix.md", "contradicts the comment rule", swap("- Do not commit.", "- No added comments.\n- Do not commit.")],
	["prompts/fix.md", "description removed", dropLineWith("description:")],
	["prompts/fix.md", "argument hint removed", dropLineWith("argument-hint:")],
	["prompts/fix.md", "no $ARGUMENTS", swap("diagnosis. $ARGUMENTS", "diagnosis.")],
];

// Deleting any rule the campaign kept must be caught. One mutant per kept rule, read from
// the lint test itself so the two lists cannot drift apart.
const lintSource = readFileSync(join(TESTS_DIR, "content.lint.test.ts"), "utf8");
const keptRules = [...lintSource.matchAll(/^\t\[("(?:[^"\\]|\\.)*"|'[^']*'), "[^"]*"\],$/gm)].map((m) => (m[1].startsWith("'") ? m[1].slice(1, -1) : JSON.parse(m[1])));
for (const rule of keptRules) {
	config.push(["AGENTS.md", `rule deleted: ${rule}`, (t) => {
		if (!t.includes(rule)) throw new Error(`kept rule not in AGENTS.md: ${rule}`);
		return t.replace(rule, "");
	}]);
}

const configMutants: Mutant[] = config.map(([target, what, apply], i) => ({ id: `C${String(i + 1).padStart(2, "0")}`, target, what, apply, tests: CONFIG_TESTS }));
const all = configMutants;

async function runTests(dir: string, tests: string[]): Promise<{ code: number; output: string }> {
	const proc = Bun.spawn(["bun", "test", "--timeout", "30000", ...tests], {
		cwd: TESTS_DIR,
		env: { ...process.env, PI_TEST_CONFIG_DIR: join(dir, "config"), PI_TEST_MUTATION: "1" },
		stdout: "pipe",
		stderr: "pipe",
		timeout: 180_000,
	});
	const [out, err, code] = await Promise.all([new Response(proc.stdout).text(), new Response(proc.stderr).text(), proc.exited]);
	return { code, output: out + err };
}

function prepare(label: string) {
	const sb = makeSandbox(label);
	cpSync(CONFIG_DIR, join(sb.dir, "config"), { recursive: true, dereference: true });
	return sb;
}

const only = process.argv.slice(2);
const selected = only.length ? all.filter((m) => only.includes(m.id)) : all;

// The unmutated copy must pass, or every "kill" below would be meaningless.
const base = prepare("mutation-baseline");
const baseline = await runTests(base.dir, CONFIG_TESTS);
base.cleanup();
if (baseline.code !== 0) {
	console.error("baseline failed: the tests do not pass on an unmutated copy\n" + baseline.output.slice(-3000));
	process.exit(2);
}
console.log(`baseline passes. running ${selected.length} mutants\n`);

// Mutants are independent (each has its own sandbox), so run a few at once.
const CONCURRENCY = Number(process.env.MUTATE_CONCURRENCY ?? 4);
const results = new Map<string, boolean>();
const queue = [...selected];
async function worker() {
	for (let m = queue.shift(); m; m = queue.shift()) {
		const sb = prepare(`mutant-${m.id}`);
		const file = join(sb.dir, "config", m.target);
		const before = readFileSync(file, "utf8");
		const after = m.apply(before);
		if (after === before) throw new Error(`${m.id} changed nothing`);
		writeFileSync(file, after);
		const { code } = await runTests(sb.dir, m.tests);
		sb.cleanup();
		results.set(m.id, code !== 0);
		console.log(`${code !== 0 ? "killed  " : "SURVIVED"} ${m.id} ${m.target}: ${m.what}`);
	}
}
await Promise.all(Array.from({ length: CONCURRENCY }, worker));
const survivors = selected.filter((m) => !results.get(m.id));
if (survivors.length) console.log(`\nsurvived:\n${survivors.map((m) => `  ${m.id} ${m.target}: ${m.what}`).join("\n")}`);

const score = Math.round(((selected.length - survivors.length) / selected.length) * 100);
console.log(`\nmutants: ${selected.length}, killed: ${selected.length - survivors.length}, survived: ${survivors.length}, score: ${score}%`);
process.exit(survivors.length ? 1 : 0);
