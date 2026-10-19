// Paths under test. PI_TEST_CONFIG_DIR lets the mutation runner point at a mutated copy.
import { existsSync, readFileSync, realpathSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

export const TESTS_DIR = resolve(import.meta.dir, "..");
export const REPO = resolve(TESTS_DIR, "../..");

/** The tracked pi config: AGENTS.md, settings.json, models.json, prompts/. */
export const CONFIG_DIR = process.env.PI_TEST_CONFIG_DIR ?? join(REPO, ".pi/agent");

/** True when the mutation runner is driving the tests against a mutated copy. */
export const UNDER_MUTATION = process.env.PI_TEST_MUTATION === "1";

export const HOME = process.env.HOME ?? "";

/**
 * The installed pi package directory, found the way a shell would find pi: walk PATH,
 * take the first executable named pi, and climb from its resolved path to the folder
 * holding pi's package.json.
 */
export function piPackageDir(): string {
	for (const dir of (process.env.PATH ?? "").split(":")) {
		if (!dir) continue;
		const candidate = join(dir, "pi");
		if (!existsSync(candidate) || !statSync(candidate).isFile()) continue;
		let at = dirname(realpathSync(candidate));
		while (at !== "/") {
			const manifest = join(at, "package.json");
			if (existsSync(manifest) && JSON.parse(readFileSync(manifest, "utf8")).name === "@earendil-works/pi-coding-agent") {
				return at;
			}
			at = dirname(at);
		}
		break;
	}
	throw new Error("installed pi package not found on PATH (expected @earendil-works/pi-coding-agent)");
}

export function readConfig(name: string): string {
	return readFileSync(join(CONFIG_DIR, name), "utf8");
}

export function readJsonConfig<T = Record<string, unknown>>(name: string): T {
	return JSON.parse(readConfig(name)) as T;
}

/** What a brand new login session on NixOS starts from, before fish adds its own paths. */
export const LOGIN_ENV: Record<string, string> = {
	HOME,
	USER: process.env.USER ?? "",
	TERM: "dumb",
	PATH: ["/run/wrappers/bin", join("/etc/profiles/per-user", process.env.USER ?? ""), "/run/current-system/sw/bin"].join(":"),
};
