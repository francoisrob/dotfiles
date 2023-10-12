{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
    initrd = {
      availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod"];
      kernelModules = [];
    };
    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/6ff5bf9c-a994-4ebf-bbf5-da8eafc3f2e2";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/8806-AB53";
      fsType = "vfat";
    };
    "/home" = {
      device = "/dev/disk/by-uuid/7ea9c209-ebe9-4d75-9af8-118ab920bf84";
      fsType = "ext4";
    };
  };

  swapDevices = [{device = "/dev/disk/by-uuid/a348d61d-4c32-4446-a01a-c87c54740fe8";}];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
