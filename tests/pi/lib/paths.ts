import { existsSync, readFileSync, realpathSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";

export const TESTS_DIR = resolve(import.meta.dir, "..");
export const REPO = resolve(TESTS_DIR, "../..");

export const CONFIG_DIR = process.env.PI_TEST_CONFIG_DIR ?? join(REPO, ".pi/agent");

export const UNDER_MUTATION = process.env.PI_TEST_MUTATION === "1";

export const HOME = process.env.HOME ?? "";

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

export const LOGIN_ENV: Record<string, string> = {
	HOME,
	USER: process.env.USER ?? "",
	TERM: "dumb",
	PATH: ["/run/wrappers/bin", join("/etc/profiles/per-user", process.env.USER ?? ""), "/run/current-system/sw/bin"].join(":"),
};
