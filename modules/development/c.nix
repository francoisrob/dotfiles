{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      gcc
      gdb
      cmake
      check
      valgrind

      binutils
      pkg-config

      bear

      clang-tools
    ];
    variables = {
    };
  };
}
