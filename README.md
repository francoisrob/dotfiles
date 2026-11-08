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
- `/etc/open-webui.env`: `OPENAI_API_KEY=...`
