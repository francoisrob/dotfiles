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
	@echo "==> $(HOST)"

.PHONY: help
help:
	@echo "Available make commands:"
	@echo "  switch         - Rebuild and switch to the new NixOS configuration"
	@echo "  home           - Build and activate the home-manager configuration"
	@echo "  update         - Update flake inputs, then switch system and home"
	@echo "  check          - Evaluate/build BOTH hosts (catches breaking the other machine)"
	@echo "  clean          - Garbage collect Nix store"
	@echo "  apply-dotfiles - Apply dotfiles using stow"
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
	@echo "==> $(shell nix eval --raw '.#nixosConfigurations' --apply 'c: builtins.concatStringsSep ", " (builtins.attrNames c)' 2>/dev/null)"
	@nix flake check

.PHONY: clean
clean:
	@sudo nix-collect-garbage -d
	@sudo nix-store --optimise

.PHONY: apply-dotfiles
apply-dotfiles:
	@stow .
