# Francois's dotfiles

Welcome to my dotfiles repo, tailored for NixOS. This setup blends NixOS's
declarative power with portability for non-Nix systems. I use GNU Stow to
manage symlinks to my config dirs, ensuring reproducibility across setups.

## Features

- Optimized for NixOS workflows
- Symlink management with Stow for cross-system use
- Simple Makefile for common tasks (see below)

## Usage

The `Makefile` provides commands to manage this setup. Run `make help` to
see all options:

### Available Commands

- **`make switch`**  
  Rebuilds and switches to the new NixOS config using the flake here.  
  _Command:_ `sudo nixos-rebuild switch --flake .`

- **`make update`**  
  Updates flake inputs and rebuilds the system.  
  _Command:_ `sudo nix flake update && make switch`

- **`make clean`**  
  Cleans the Nix store and optimizes it.  
  _Command:_ `sudo nix-collect-garbage -d && nix-store --optimise`

- **`make apply-dotfiles`**  
  Applies dotfiles by creating symlinks with Stow.  
  _Command:_ `stow .`

## Installation

1. Clone this repo to your desired spot (e.g., `~/dotfiles`).
2. Run `make apply-dotfiles` to symlink the dotfiles.
3. For NixOS, use `make switch` to apply the config.

## Notes

- Ensure GNU Stow and Nix is installed.
- Adjust paths in the dotfiles if your setup varies.
