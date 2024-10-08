# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{ config
, lib
, pkgs
, ...
}: {
  imports = [
    ./storage.nix

  ];
  config = {
    mySystem.purpose = "Network Attached Storage";
    mySystem.system.impermanence.enable = true;
    mySystem.system.autoUpgrade.enable = true; # bold move cotton
    mySystem.services = {
      openssh.enable = true;
      # minio.enable = true;
      # syncthing = {
      #   enable = true;
      #   syncPath = "/tank/syncthing/";
      # };
    };
    # mySystem.security.acme.enable = true;

    mySystem.nasFolder = "/tank";
    mySystem.system.resticBackup.local.location = "/tank/backup/nixos/nixos";

    mySystem.system = {
      zfs.enable = true;
      zfs.mountPoolsAtBoot = [ "rpool" ];
    };

    mySystem.services.nfs.enable = true;
    # mySystem.system.motd.networkInterfaces = [ "eno2" ];




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

    networking.hostName = "mnas"; # Define your hostname.
    networking.hostId = "8425e349"; # for zfs, helps stop importing to wrong machine
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

  swapDevices = [ ];

    # TODO
    # fileSystems."/mnt/cache" =
    #   {
    #     device = "/dev/disk/by-uuid/fe725638-ca41-4ecc-9b8a-7bf0807786e1";
    #     fsType = "xfs";
    #   };

    # TODO does this live somewhere else?
    # it is very machine-specific...
    # add user with `sudo smbpasswd -a my_user`
    services.samba = {
      enable = true;
      openFirewall = true;
      extraConfig = ''
        workgroup = WORKGROUP
        server string = mnas
        netbios name = mnas
        security = user
        #use sendfile = yes
        #max protocol = smb2
        # note: localhost is the ipv6 localhost ::1
        hosts allow = 192.168.10. 192.168.1. 127.0.0.1 localhost
        hosts deny = 0.0.0.0/0
        guest account = nobody
        map to guest = bad user
      '';
      shares = {
        media = {
          path = "/tank/media";
          "read only" = "no";
        };
        games = {
          path = "/tank/games";
          "read only" = "no";
        };
        ai = {
          path = "/tank/ai";
          "read only" = "no";
        };
      };

    };
    services.samba-wsdd.enable = true; # make shares visible for windows 10 clients

    environment.systemPackages = with pkgs; [
      btrfs-progs

    ];



    environment.persistence."${config.mySystem.system.impermanence.persistPath}" = lib.mkIf config.mySystem.system.impermanence.enable {
      directories = [ "/var/lib/samba/" ];
    };


  };
}
