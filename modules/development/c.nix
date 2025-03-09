{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      # C development tools
      gcc
      gdb
      cmake
      check
      valgrind

      # Build essentials
      binutils
      pkg-config

      # For generating compile_commands.json
      bear 

      # For clangd, static analysis, etc.
      clang-tools
    ];
  };
}
