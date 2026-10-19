// Throwaway test dirs under tests/pi/.sandbox (gitignored), never /tmp.
import { mkdirSync, mkdtempSync, rmSync } from "node:fs";
import { join } from "node:path";
import { TESTS_DIR } from "./paths";

export const SANDBOX_ROOT = join(TESTS_DIR, ".sandbox");

export function makeSandbox(label: string): { dir: string; cleanup: () => void } {
	mkdirSync(SANDBOX_ROOT, { recursive: true });
	const dir = mkdtempSync(join(SANDBOX_ROOT, `${label}-`));
	return { dir, cleanup: () => rmSync(dir, { recursive: true, force: true }) };
}
