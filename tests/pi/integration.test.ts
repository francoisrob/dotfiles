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

describe("files on disk", () => {
	test("the sandbox links resolve to the files under test", () => {
		expect(readFileSync(join(agentDir, "AGENTS.md"), "utf8")).toBe(readConfig("AGENTS.md"));
	});
});
