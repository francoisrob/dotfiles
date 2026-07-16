.PHONY: help
help:
	@echo "Available make commands:"
	@echo "  switch         - Rebuild and switch to the new NixOS configuration"
	@echo "  home           - Build and activate the home-manager configuration"
	@echo "  update         - Update flake inputs, then switch system and home"
	@echo "  clean          - Garbage collect Nix store"
	@echo "  apply-dotfiles - Apply dotfiles using stow"

.PHONY: switch
switch:
	@sudo nixos-rebuild switch --flake .

.PHONY: home
home:
	@nix run .#home-manager -- switch -b backup --flake .

.PHONY: update
update:
	@nix flake update
	@$(MAKE) switch
	@$(MAKE) home

.PHONY: clean
clean:
	@sudo nix-collect-garbage -d
	@sudo nix-store --optimise

.PHONY: apply-dotfiles
apply-dotfiles:
	@stow .
