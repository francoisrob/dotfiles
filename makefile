FLAKE ?= $(PWD)/flake

.PHONY: help
help:
	@echo "Available make commands:"
	@echo "  apply-dotfiles - Apply dotfiles using stow"

.PHONY: apply-dotfiles
apply-dotfiles:
	@stow .
