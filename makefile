HOST ?= $(shell hostname)

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

.PHONY: check
check:
	@echo "hosts: $(shell nix eval --raw '.#nixosConfigurations' --apply 'c: builtins.concatStringsSep ", " (builtins.attrNames c)' 2>/dev/null)"
	@nix flake check

.PHONY: clean
clean:
	@sudo nix-collect-garbage -d
	@sudo nix-store --optimise

STOW_TARGET ?= ..

.PHONY: apply-dotfiles
apply-dotfiles:
	@mkdir -p $(STOW_TARGET)/.pi/agent/extensions
	@stow -t $(STOW_TARGET) .

.PHONY: test-pi
test-pi:
	@cd tests/pi && bun install --frozen-lockfile && bun test --timeout 30000

.PHONY: test-pi-e2e
test-pi-e2e: test-pi
	@cd tests/pi && PI_E2E=1 bun test --timeout 300000 e2e.test.ts

.PHONY: mutate-pi
mutate-pi:
	@cd tests/pi && bun install --frozen-lockfile && bun mutate.ts
