{pkgs, ...}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    loader = {
      timeout = 0;
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
    };
    supportedFilesystems = ["ntfs"];
    consoleLogLevel = 0;
    kernel.sysctl."kernel.sysrq" = 1;
    kernelParams = [
      "quiet"
      "8250.nr_uarts=0"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "mitigations=off"
    ];
    tmp = {
      useTmpfs = true;
      tmpfsSize = "4G";
    };
  };

  environment.etc."issue".text = "";
}
