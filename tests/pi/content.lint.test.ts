// Lint for AGENTS.md and the prompt templates. Each rule exists because a real run broke it.
import { describe, expect, test } from "bun:test";
import { existsSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { CONFIG_DIR, HOME, readConfig } from "./lib/paths";

const agents = readConfig("AGENTS.md");
const promptNames = readdirSync(join(CONFIG_DIR, "prompts")).filter((f) => f.endsWith(".md"));
const prompts = Object.fromEntries(promptNames.map((f) => [f, readConfig(`prompts/${f}`)]));
const allFiles: Record<string, string> = { "AGENTS.md": agents, ...Object.fromEntries(promptNames.map((f) => [`prompts/${f}`, prompts[f]])) };

// AGENTS.md is resent on every request, so its size is a cost on every call.
const AGENTS_WORD_BUDGET = 1200;
const EM_DASH = String.fromCharCode(0x2014);

const words = (s: string) => s.split(/\s+/).filter(Boolean);
const bullets = (s: string) => s.split("\n").filter((l) => /^\s*(-|\d+\.)\s/.test(l)).map((l) => l.replace(/^\s*(-|\d+\.)\s/, "").trim());
const wordSet = (s: string) => new Set(s.toLowerCase().match(/[a-z0-9']+/g) ?? []);
function jaccard(a: string, b: string) {
	const x = wordSet(a);
	const y = wordSet(b);
	const inter = [...x].filter((w) => y.has(w)).length;
	return inter / (x.size + y.size - inter || 1);
}
const headings = agents.split("\n").filter((l) => l.startsWith("## ")).map((l) => l.slice(3).trim());

describe("every instruction file", () => {
	for (const [name, text] of Object.entries(allFiles)) {
		test(`${name}: no em dash character`, () => {
			expect(text.includes(EM_DASH)).toBe(false);
		});

		test(`${name}: no gendered pronouns for the owner`, () => {
			expect(text.match(/\b(he|him|his|himself)\b/gi) ?? []).toEqual([]);
		});

		test(`${name}: no leftovers from the test bench (fixture names or its test counts)`, () => {
			expect(text.match(/elysia|ledger fixture|\b\d+ pass\b|\b\d+ skip\b|\b\d+ fail\b/gi) ?? []).toEqual([]);
		});
	}
});

describe("AGENTS.md", () => {
	test(`stays within ${AGENTS_WORD_BUDGET} words (it is resent on every request)`, () => {
		expect(words(agents).length).toBeLessThanOrEqual(AGENTS_WORD_BUDGET);
	});

	test("does not tie the full-suite rule to one project's test command", () => {
		expect(agents).not.toMatch(/`bun test` here/);
		expect(agents).toMatch(/full test command/);
	});

	test("shows the test-result line as `command: result`, with placeholders and no dash", () => {
		const example = agents.match(/in the form `([^`]+)`/)?.[1] ?? "";
		expect(example).toMatch(/^<[^>]+>: <[^>]+> pass, <[^>]+> fail$/);
	});

	test("every home-folder path it names exists on this machine", () => {
		const paths = [...agents.matchAll(/~\/[A-Za-z0-9._/-]*[A-Za-z0-9_/]/g)].map((m) => m[0]);
		expect(paths.length).toBeGreaterThan(0);
		expect(paths.filter((p) => !existsSync(p.replace(/^~/, HOME)))).toEqual([]);
	});

	test("says where the helper tools are documented, and that place exists", () => {
		expect(agents).toContain("~/hub/tools/README.md");
		expect(agents).not.toMatch(/Each has a README next to its source/);
	});

	test("has no repeated lines and no repeated headings", () => {
		const lines = agents.split("\n").map((l) => l.trim()).filter(Boolean);
		expect(lines.filter((l, i) => lines.indexOf(l) !== i)).toEqual([]);
		expect(headings.filter((h, i) => headings.indexOf(h) !== i)).toEqual([]);
	});
});

// Rules the tuning campaign kept (~/projects/pi-project), each with its origin. Pinned so
// deleting one is a decision, not an accident.
const KEPT_RULES: Array<[string, string]> = [
	["Ignore any root-cause theory in the report", "gen-05"],
	["Reproduce before touching non-test code", "gen-05"],
	['"No fix needed" is a valid result', "gen-06"],
	["git log --oneline -15 -- <paths>", "gen-01 to gen-04"],
	["Trace the bad value backward to where it originates", "research"],
	["After two failed fixes, stop and report", "research"],
	["The fix is the minimum diff that makes the repro pass", "research, gen-05"],
	["run the project's full test command once", "gen-27, gen-28"],
	["temp file in the working directory, never /tmp", "gen-10, owner rule"],
	["paste the trimmed failing-then-passing test output", "gen-07, gen-11"],
	["Mention unrelated problems you noticed; do not fix them", "gen-35"],
	["Never hand-write type stubs, shims, polyfills, or fake modules", "gen-09"],
	["no fudge loops", "gen-21"],
	["no retries to hide flakiness", "gen-18, gen-19"],
	["A length limit in the request is a hard limit", "gen-08, gen-42"],
	["Not verified on <system>", "gen-33, gen-38"],
	["at most three short paragraphs and under 120 words", "gen-26, gen-40"],
	["No em dashes", "owner rule, gen-39"],
	["A command and its result are written `command: result`", "gen-40"],
	["the bash tool runs /bin/bash", "gen-41"],
	['"status?" = three short lists: Done, Left, Needs you', "gen-24"],
	['"commit it" = commit only your own changes, never push', "gen-24"],
	['"lmk" = report, then stop', "gen-29"],
	["A message that discusses or asks is not permission to act", "gen-30"],
	["Never `cat` a whole file to see part of it", "research"],
	["Never push, never create branches, never commit unless asked", "owner rule"],
];

describe("AGENTS.md keeps every rule the campaign kept", () => {
	for (const [rule, provenBy] of KEPT_RULES) {
		test(`${rule} (${provenBy})`, () => {
			expect(agents).toContain(rule);
		});
	}
});

describe("prompt templates", () => {
	const agentRules = bullets(agents);

	for (const [name, text] of Object.entries(prompts)) {
		test(`${name}: its header declares a description and an argument hint (pi would silently fall back to the first line)`, () => {
			const header = text.match(/^---\n([\s\S]*?)\n---\n/)?.[1] ?? "";
			expect(header).toMatch(/^description: .{10,}$/m);
			expect(header).toMatch(/^argument-hint: .+$/m);
		});

		test(`${name}: does not restate a rule from AGENTS.md (one copy per rule, so they cannot drift)`, () => {
			const restated = bullets(text)
				.map((line) => ({ line, best: Math.max(...agentRules.map((r) => jaccard(line, r))) }))
				.filter((x) => x.best >= 0.4)
				.map((x) => x.line);
			expect(restated).toEqual([]);
		});

		test(`${name}: leaves rules AGENTS.md owns to AGENTS.md (comments, test runs, git history, hypotheses, temp files, evidence)`, () => {
			const body = text.replace(/^---[\s\S]*?---/, "");
			expect(body.match(/comment|full suite|wider suite|test file|git log|git blame|hypothes|temp file|paste/gi) ?? []).toEqual([]);
		});

		test(`${name}: every AGENTS.md section it points to exists`, () => {
			const refs = [...text.matchAll(/"([^"]+)" (?:section|rules)/g)].map((m) => m[1]);
			expect(refs.length).toBeGreaterThan(0);
			expect(refs.filter((r) => !headings.some((h) => h.startsWith(r)))).toEqual([]);
		});
	}
});
