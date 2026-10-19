// Load the config through the installed pi's own loaders, from a sandbox agent dir. Offline.
import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { readFileSync, symlinkSync } from "node:fs";
import { join } from "node:path";
import { CONFIG_DIR, piPackageDir, readConfig, readJsonConfig } from "./lib/paths";
import { makeSandbox } from "./lib/sandbox";

const pi = await import(join(piPackageDir(), "dist/index.js"));
const settingsFile = readJsonConfig<Record<string, any>>("settings.json");

let agentDir = "";
let cwd = "";
let cleanup = () => {};

beforeAll(() => {
	const sb = makeSandbox("integration");
	cleanup = sb.cleanup;
	agentDir = join(sb.dir, "agent");
	cwd = join(sb.dir, "project");
	Bun.spawnSync(["mkdir", "-p", agentDir, cwd]);
	for (const name of ["AGENTS.md", "settings.json", "models.json", "prompts"]) {
		symlinkSync(join(CONFIG_DIR, name), join(agentDir, name));
	}
	Bun.spawnSync(["mkdir", "-p", join(agentDir, "extensions")]);
	symlinkSync(join(CONFIG_DIR, "extensions/metrics"), join(agentDir, "extensions/metrics"));
});
afterAll(() => cleanup());

describe("pi's settings loader", () => {
	test("loads settings.json with no errors and the intended values", () => {
		const sm = pi.SettingsManager.create(cwd, agentDir);
		expect(sm.drainErrors()).toEqual([]);
		expect(sm.getDefaultModel()).toBe(settingsFile.defaultModel);
		expect(sm.getDefaultThinkingLevel()).toBe(settingsFile.defaultThinkingLevel);
		expect(sm.getDefaultTools()).toEqual(settingsFile.defaultTools);
		expect(sm.getCompactionSettings()).toEqual(settingsFile.compaction);
	});
});

describe("pi's model runtime", () => {
	test("the default model exists and gets the capped context window from models.json", async () => {
		const rt = await pi.ModelRuntime.create({
			modelsPath: join(agentDir, "models.json"),
			authPath: join(agentDir, "auth.json"),
			allowModelNetwork: false,
			refreshOnCreate: false,
		});
		expect(rt.getError()).toBeUndefined();
		const model = rt.getModel(settingsFile.defaultProvider, settingsFile.defaultModel);
		expect(model).toBeTruthy();
		const override = readJsonConfig<any>("models.json").providers[settingsFile.defaultProvider].modelOverrides[settingsFile.defaultModel];
		expect(model.contextWindow).toBe(override.contextWindow);
	});

	test("every overridden model exists in pi's catalog (no stale overrides)", async () => {
		const rt = await pi.ModelRuntime.create({ modelsPath: join(agentDir, "models.json"), authPath: join(agentDir, "auth.json"), allowModelNetwork: false, refreshOnCreate: false });
		const providers = readJsonConfig<any>("models.json").providers;
		for (const [provider, cfg] of Object.entries<any>(providers)) {
			for (const id of Object.keys(cfg.modelOverrides)) expect(rt.getModel(provider, id), `${provider}/${id}`).toBeTruthy();
		}
	});
});

describe("pi's resource loader", () => {
	let loader: any;
	beforeAll(async () => {
		const sm = pi.SettingsManager.create(cwd, agentDir);
		loader = new pi.DefaultResourceLoader({ cwd, agentDir, settingsManager: sm, noExtensions: true, noSkills: true, noThemes: true });
		await loader.reload();
	});

	test("loads AGENTS.md as the one global context file, byte for byte", () => {
		const files = loader.getAgentsFiles().agentsFiles;
		expect(files.map((f: any) => f.path)).toEqual([join(agentDir, "AGENTS.md")]);
		expect(files[0].content).toBe(readConfig("AGENTS.md"));
	});

	test("loads both prompt templates with a description and an argument hint, and no diagnostics", () => {
		const { prompts, diagnostics } = loader.getPrompts();
		expect(diagnostics).toEqual([]);
		expect(prompts.map((p: any) => p.name).sort()).toEqual(["diagnose", "fix"]);
		for (const p of prompts) {
			expect(p.description.length).toBeGreaterThan(10);
			expect(p.argumentHint.length).toBeGreaterThan(0);
			expect(p.content).toContain("$ARGUMENTS");
		}
	});
});

describe("pi's extension loader", () => {
	// In node, which pi runs on, not inside this bun process.
	test("loads the metrics extension with no errors, registering /usage and its event handlers", () => {
		const script = `
			const pi = await import(${JSON.stringify(join(piPackageDir(), "dist/index.js"))});
			const [cwd, agentDir] = process.argv.slice(1);
			const sm = pi.SettingsManager.create(cwd, agentDir);
			const loader = new pi.DefaultResourceLoader({ cwd, agentDir, settingsManager: sm, noSkills: true, noThemes: true, noPromptTemplates: true });
			await loader.reload();
			const { extensions, errors } = loader.getExtensions();
			const metrics = extensions.filter((e) => e.path.includes("extensions/metrics"));
			console.log(JSON.stringify({ errors, count: metrics.length, commands: metrics.flatMap((e) => [...e.commands.keys()]), handlers: metrics.flatMap((e) => [...e.handlers.keys()]) }));
		`;
		const node = Bun.which("node");
		expect(node).toBeTruthy();
		const r = Bun.spawnSync([node!, "--input-type=module", "-e", script, cwd, agentDir], { timeout: 60_000 });
		expect(r.stderr.toString()).toBe("");
		const out = JSON.parse(r.stdout.toString().trim().split("\n").at(-1) ?? "{}");
		expect(out.errors).toEqual([]);
		expect(out.count).toBe(1);
		expect(out.commands).toEqual(["usage"]);
		for (const name of ["session_start", "agent_start", "agent_settled", "session_shutdown"]) expect(out.handlers, name).toContain(name);
	});
});

describe("files on disk", () => {
	test("the sandbox links resolve to the files under test", () => {
		expect(readFileSync(join(agentDir, "AGENTS.md"), "utf8")).toBe(readConfig("AGENTS.md"));
	});
});
