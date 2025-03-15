.PHONY: help
help:
	@echo "Available make commands:"
	@echo "  switch         - Rebuild and switch to the new NixOS configuration"
	@echo "  update         - Update flake inputs and system"
	@echo "  clean          - Garbage collect Nix store"
	@echo "  apply-dotfiles - Apply dotfiles using stow"

.PHONY: switch
switch:
	@sudo nixos-rebuild switch --flake .

.PHONY: update
update:
	@sudo nix flake update
	@$(MAKE) switch

.PHONY: clean
clean:
	@sudo nix-collect-garbage -d
	@sudo nix-store --optimise

.PHONY: apply-dotfiles
apply-dotfiles:
	@stow .
