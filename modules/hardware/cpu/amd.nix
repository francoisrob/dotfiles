{pkgs, ...}: {
  boot = {
    kernelModules = [
      "kvm-amd"
    ];
  };

  environment = {
    systemPackages = with pkgs; [
      lm_sensors
    ];
  };
}
