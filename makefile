# Which host to build. Defaults to this machine's hostname, which matches the
# attribute names in flake.nix (laptop / minipc), so a bare `make switch` does
# the right thing once a host is running its own config.
#
# Override it when the hostname does not match yet -- notably the very first
# rebuild on a freshly installed machine, where the installer's hostname is
# still "nixos":
#
#   make switch HOST=minipc
#
# There is deliberately no "nixos" attribute in the flake, so getting this
# wrong fails with "attribute not found" rather than silently building the
# other machine's config.
HOST ?= $(shell hostname)

# Runs before sudo prompts, so a bare `make switch` names its target instead of
# leaving you to infer it from the store path printed once the build is done.
.PHONY: banner
banner:
	@echo "host: $(HOST)"

.PHONY: help
help:
	@echo "Available make commands:"
	@echo "  switch         - Rebuild and switch to the new NixOS configuration"
	@echo "  home           - Build and activate the home-manager configuration"
	@echo "  update         - Update flake inputs, then switch system and home"
	@echo "  check          - Evaluate/build BOTH hosts (catches breaking the other machine)"
	@echo "  clean          - Garbage collect Nix store"
	@echo "  apply-dotfiles - Apply dotfiles using stow"
	@echo "  test-pi        - Test the pi config (no model calls)"
	@echo "  test-pi-e2e    - Same, plus end-to-end runs against the real model"
	@echo "  mutate-pi      - Mutation-test the pi tests (every deliberate break must be caught)"
	@echo ""
	@echo "Current HOST=$(HOST) (override with: make switch HOST=minipc)"

.PHONY: switch
switch: banner
	@sudo nixos-rebuild switch --flake .#$(HOST)

.PHONY: home
home: banner
	@nix run .#home-manager -- switch -b backup --flake .#francois@$(HOST)

.PHONY: update
update:
	@nix flake update
	@$(MAKE) switch
	@$(MAKE) home

# Builds every host and home config. Run this before pushing a change to a
# shared module -- it is the only thing that catches breaking the machine you
# are not sitting at.
.PHONY: check
check:
	@echo "hosts: $(shell nix eval --raw '.#nixosConfigurations' --apply 'c: builtins.concatStringsSep ", " (builtins.attrNames c)' 2>/dev/null)"
	@nix flake check

.PHONY: clean
clean:
	@sudo nix-collect-garbage -d
	@sudo nix-store --optimise

# Where stow links into. Stow's own default is the parent of this repo (~); the
# tests override it to link into a throwaway folder.
STOW_TARGET ?= ..

# Stow links a whole folder into the repo when that folder does not exist in the
# target yet. pi writes its login (auth.json), tokens and sessions into
# ~/.pi/agent and installs local extensions into ~/.pi/agent/extensions, so both
# are created as real folders first. Stow then links pi's config file by file,
# and pi's own files stay out of the repo.
.PHONY: apply-dotfiles
apply-dotfiles:
	@mkdir -p $(STOW_TARGET)/.pi/agent/extensions
	@stow -t $(STOW_TARGET) .

# pi coding agent config (.pi/agent). See tests/pi.
.PHONY: test-pi
test-pi:
	@cd tests/pi && bun install --frozen-lockfile && bun test --timeout 30000

.PHONY: test-pi-e2e
test-pi-e2e: test-pi
	@cd tests/pi && PI_E2E=1 bun test --timeout 300000 e2e.test.ts

.PHONY: mutate-pi
mutate-pi:
	@cd tests/pi && bun install --frozen-lockfile && bun mutate.ts
