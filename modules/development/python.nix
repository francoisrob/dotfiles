{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      python3
      (python3.withPackages (ps:
        with ps; [
          setuptools
          pip
        ]))
    ];
  };
}
