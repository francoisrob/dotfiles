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
    variables = {
       # C_INCLUDE_PATH = "${pkgs.glibc.dev}/include:${pkgs.glibc}/include";
       # CPLUS_INCLUDE_PATH = "${pkgs.glibc.dev}/include:${pkgs.glibc}/include:${pkgs.stdenv.cc.cc}/include/c++/${pkgs.stdenv.cc.cc.version}";
    };
  };
}
