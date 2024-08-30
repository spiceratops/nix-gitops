# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {
  imports = [


  ];

  mySystem.services = {

    openssh.enable = true;
    cfDdns.enable = true;
    powerdns = {
      enable = true;
      admin-ui = false;
    };
    # adguardhome.enable = true;
  };

    mySystem.system = {
      zfs.enable = true;
      zfs.mountPoolsAtBoot = [ "rpool" ];
    };

  # no mutable state I care about
  mySystem.system.resticBackup =
    {
      local.enable = false;
      remote.enable = false;
    };
  mySystem.system.autoUpgrade = {
    enable = true;
  };



    boot = {

      initrd.availableKernelModules = [ "uhci_hcd" "ehci_pci" "ahci" "mpt3sas" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];
      initrd.kernelModules = [ ];
      kernelModules = [ "kvm-intel" ];
      extraModulePackages = [ ];

      # for managing/mounting ntfs
      supportedFilesystems = [ "ntfs" ];

      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        # why not ensure we can memtest workstatons easily?
        grub.memtest86.enable = true;

      };
    };

    networking.hostName = "dns01"; # Define your hostname.
    networking.hostId = "e3657900"; # for zfs, helps stop importing to wrong machine
    networking.useDHCP = lib.mkDefault true;

    fileSystems."/" =
      {
        device = "rpool/local/root";
        fsType = "zfs";
      };

    fileSystems."/boot" =
      {
        device = "/dev/disk/by-label/EFI";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };

    fileSystems."/nix" =
      {
        device = "rpool/local/nix";
        fsType = "zfs";
      };

    fileSystems."/persist" =
      {
        device = "rpool/safe/persist";
        fsType = "zfs";
        neededForBoot = true; # for impermanence
      };



}
