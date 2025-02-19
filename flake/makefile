.PHONY: help
help:
	@echo "Available make commands:"
	@echo "  switch         - Rebuild and switch to the new NixOS configuration"
	@echo "  update         - Update flake inputs and system"
	@echo "  clean          - Garbage collect Nix store"

.PHONY: switch
switch:
	@sudo nixos-rebuild switch --flake .#$(CONFIG)

.PHONY: update
update:
	@sudo nix flake update
	@$(MAKE) switch CONFIG=$(CONFIG)

.PHONY: clean
clean:
	@sudo nix-collect-garbage -d
	@sudo nix-store --optimise
