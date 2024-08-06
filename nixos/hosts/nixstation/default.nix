# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {
  mySystem.purpose = "Development";
  mySystem.services = {
    openssh.enable = true;
    podman.enable = true;
    nginx.enable = true;
    code-server.enable = true;
    postgresql =
      { enable = true; backup = false; };

  };


  mySystem.nfs.nas.enable = true;
  mySystem.persistentFolder = "/persistent";
  mySystem.system.motd.networkInterfaces = [ "eno1" ];
  mySystem.security.acme.enable = true;

  # Dev machine
  mySystem.system.resticBackup =
    {
      local.enable = false;
      remote.enable = false;
    };

  boot = {

    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    initrd.kernelModules = [ ];
    kernelModules = [ ];
    extraModulePackages = [ ];

    # for managing/mounting ntfs
    supportedFilesystems = [ "ntfs" ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      # why not ensure we can memtest workstatons easily?
      # TODO check whether this is actually working, cant see it in grub?
      grub.memtest86.enable = true;

    };
  };

  networking.hostName = "nixstation"; # Define your hostname.
  networking.useDHCP = lib.mkDefault true;

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/027313d9-415d-4fb9-9976-cdecaa58090a";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/C572-7537";
      fsType = "vfat";
    };

  # TODO
  # swapDevices =
  #   [{ device = "/dev/disk/by-uuid/0ae2765b-f3f4-4b1a-8ea6-599f37504d70"; }];

}
