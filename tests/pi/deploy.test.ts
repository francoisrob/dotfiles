// Is this machine running the tracked config? Reads live state, so mutation runs skip it.
import { describe, expect, test } from "bun:test";
import { existsSync, lstatSync, readFileSync, realpathSync } from "node:fs";
import { join } from "node:path";
import { HOME, LOGIN_ENV, REPO, UNDER_MUTATION, piPackageDir } from "./lib/paths";

const live = join(HOME, ".pi/agent");
const d = UNDER_MUTATION ? describe.skip : describe;

d("stow links", () => {
	for (const name of ["AGENTS.md", "settings.json", "models.json", "prompts"]) {
		test(`~/.pi/agent/${name} is a link into the dotfiles repo`, () => {
			expect(lstatSync(join(live, name)).isSymbolicLink()).toBe(true);
			expect(realpathSync(join(live, name))).toBe(join(REPO, ".pi/agent", name));
		});
	}

	test("no wrapper is left in ~/.local/bin to shadow the real pi (removed 2026-10-18)", () => {
		expect(() => lstatSync(join(HOME, ".local/bin/pi"))).toThrow();
		expect(existsSync(join(REPO, ".local/bin/pi"))).toBe(false);
	});

	test("secrets and state in ~/.pi/agent are real local files, not tracked", () => {
		for (const name of ["auth.json", "sessions"]) {
			if (!existsSync(join(live, name))) continue;
			expect(lstatSync(join(live, name)).isSymbolicLink()).toBe(false);
		}
		const tracked = Bun.spawnSync(["git", "-C", REPO, "ls-files", ".pi"]).stdout.toString().split("\n").filter(Boolean);
		expect(tracked.filter((f) => /auth|sessions|models-store|trust/.test(f))).toEqual([]);
	});

	test("no links are left pointing at the old ~/hub/pi location", () => {
		const out = Bun.spawnSync(["find", live, "-maxdepth", "1", "-type", "l", "-lname", "*hub/pi*"]).stdout.toString().trim();
		expect(out).toBe("");
	});
});

d("PATH", () => {
	test("a new fish login shell resolves bare `pi` to the bun-installed pi", () => {
		const out = Bun.spawnSync(["fish", "--login", "-c", "command -v pi"], { env: LOGIN_ENV }).stdout.toString().trim();
		expect(realpathSync(out).startsWith(piPackageDir() + "/")).toBe(true);
	});

	test("pi runs from a non-interactive fish shell too (scripts, cron, ssh host cmd)", () => {
		const r = Bun.spawnSync(["fish", "--login", "-c", "pi --version"], { env: LOGIN_ENV });
		expect(r.stderr.toString()).toBe("");
		expect(r.exitCode).toBe(0);
	});

	test("fish's own PATH list no longer carries the removed ~/hub/bin", () => {
		const out = Bun.spawnSync(["fish", "-c", "string join \\n $fish_user_paths"], { env: LOGIN_ENV }).stdout.toString();
		expect(out.split("\n")).not.toContain(join(HOME, "hub/bin"));
	});
});

d("installed pi", () => {
	test("bare `pi` in fish reports the installed package's version", () => {
		const version = JSON.parse(readFileSync(join(piPackageDir(), "package.json"), "utf8")).version;
		const out = Bun.spawnSync(["fish", "--login", "-c", "pi --version"], { env: LOGIN_ENV }).stdout.toString().trim();
		expect(out).toBe(version);
	});

	test("every package listed in settings.json is installed", () => {
		const settings = JSON.parse(readFileSync(join(REPO, ".pi/agent/settings.json"), "utf8"));
		for (const spec of settings.packages as string[]) {
			const name = spec.replace(/^npm:/, "");
			expect(existsSync(join(live, "npm/node_modules", name, "package.json")), name).toBe(true);
		}
	});
});
