# dotfiles

NixOS flake for two hosts (`laptop`, `minipc`), a standalone home-manager config, and app configs linked into `~` with GNU Stow.

## Layout

- `flake.nix`: inputs, per-host tuning, outputs
- `hosts/<host>/`: host config and hardware
- `modules/`: shared NixOS modules (`system/`, `hardware/`, `programs/`, `virtualisation/`, `development/`)
- `home-manager/`: user packages and services
- `.config/`, `.claude/`, `.pi/`, `.profile`: stowed into `~`

## Commands

| Command | Does |
| --- | --- |
| `make switch` | Rebuild and switch the system for `$(hostname)` (`HOST=minipc` to override) |
| `make home` | Build and activate home-manager |
| `make update` | `nix flake update`, then `switch` and `home` |
| `make check` | Build every host and home config |
| `make clean` | Garbage-collect and optimise the store |
| `make apply-dotfiles` | Stow the dotfiles into `~` |
| `make test-pi` | Test the pi config |

## New machine

1. Clone to `~/dotfiles`.
2. `make apply-dotfiles`
3. `make switch HOST=<host>`, then `make home`.

## Secrets kept outside the repo

Root-only env files, created by hand before the first `make switch` on `minipc`:

- `/etc/webdav.env`: `SEEDVAULT_PASSWORD=...`
- `/etc/freellmapi.env`: `ENCRYPTION_KEY=...`

User-owned, created by hand when needed:

- `~/.config/hermes/secrets.env`: Hermes gateway platform settings and tokens (`NTFY_*`, `KEY=value` lines). `make home` merges it into `~/.hermes/.env`; a missing file only prints a warning.
- `~/.config/ntfy/secrets.env`: `NTFY_AUTH_USERS` (bcrypt hash) and `NTFY_AUTH_TOKENS` for the ntfy server; `phone-password` beside it.
- `~/.config/axiom/tokens/hermes.token`: Hermes' axiom access token, minted on terraria (see `~/hub/README.md`).

## AI services (`home-manager/ai.nix`)

- `llama-server`: local models on `127.0.0.1:3080`.
- `hermes-agent`: Hermes Agent gateway from the `hermes-agent` flake input (its home-manager module). The gateway runs on `minipc` only. `~/.hermes/config.yaml` is generated, so change settings here, not with `hermes config set`.
- `herdr` (minipc): `herdr server` at boot. The Ovis phone app runs inside it as a herdr plugin (installed with `herdr plugin install devswha/ovis --ref <tag>`, not by Nix).
- `ntfy` (minipc): push server on `127.0.0.1:2586` for Hermes.
- `scratch-clean`: daily timer that deletes `~/hub/scratch` entries not written for 60 days. Run `scratch-clean` for a dry run.
