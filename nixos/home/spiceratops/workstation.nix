{ lib, pkgs, self, config, inputs, ... }:
with config;
{
  imports = [
    ./global.nix
  ];


  myHome.security = {
    ssh = {
      #TODO make this dynamic
      enable = true;
      matchBlocks = {
        mnas = {
          hostname = "mnas";
          port = 22;
          identityFile = "~/.ssh/id_ed25519";
        };
        nixstation = {
          hostname = "nixstation";
          port = 22;
          identityFile = "~/.ssh/id_ed25519";
        };
      };
    };
  };


  myHome = {
    programs = {
      firefox.enable = true;
    };
    shell = {

      starship.enable = true;
      fish.enable = true;

    };
  };

  home = {
    # Install these packages for my user
    packages = with pkgs;
      [
        #apps
        orca-slicer
        _1password-gui
        flameshot
        vlc

        # cli
        bat
        dbus
        direnv
        git
        nix-index
        python3
        fzf
        ripgrep
        syncthing

        brightnessctl

        # office
        onlyoffice-bin


      ];

  };
}
