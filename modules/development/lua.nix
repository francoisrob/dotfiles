{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      lua
      luajitPackages.luarocks
      stylua
    ];
  };
}
