// settings.json against the schema of the installed pi.
import { describe, expect, test } from "bun:test";
import Ajv2020 from "ajv/dist/2020";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { piPackageDir, readJsonConfig } from "./lib/paths";

const PI = piPackageDir();
const schema = (name: string) => JSON.parse(readFileSync(join(PI, "schemas", `${name}.schema.json`), "utf8"));
const settings = readJsonConfig<Record<string, any>>("settings.json");

function validate(name: string, data: unknown) {
	const ajv = new Ajv2020({ strict: false, allErrors: true });
	const ok = ajv.validate(schema(name), data);
	return ok ? [] : (ajv.errors ?? []).map((e) => `${e.instancePath || "/"} ${e.message}`);
}

describe("settings.json", () => {
	test("is valid against the installed pi's settings schema", () => {
		expect(validate("settings", settings)).toEqual([]);
	});

	test("uses only keys pi knows (the schema allows unknown keys, so a typo would pass silently)", () => {
		const known = Object.keys(schema("settings").properties);
		expect(Object.keys(settings).filter((k) => !known.includes(k))).toEqual([]);
	});

	test("default tools are all real pi tools", async () => {
		const { allToolNames } = await import(join(PI, "dist/core/tools/index.js"));
		expect(settings.defaultTools.filter((t: string) => !allToolNames.has(t))).toEqual([]);
	});

	test("telemetry and analytics stay off", () => {
		expect(settings.enableInstallTelemetry).toBe(false);
		expect(settings.enableAnalytics).toBe(false);
	});

	test("pi retries failed requests itself and the provider SDK does not, so retries never stack", () => {
		expect(settings.retry.enabled).toBe(true);
		expect(settings.retry.provider.maxRetries).toBe(0);
	});

	test("npm runs without its update notifier (it prints into pi's output)", () => {
		expect(settings.npmCommand).toContain("--no-update-notifier");
	});
});
