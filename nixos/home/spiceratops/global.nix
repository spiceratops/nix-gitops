{ lib, pkgs, self, config, ... }:
with config;
{

  imports = [
    ../modules
  ];

  config = {
    myHome.username = "spiceratops";
    myHome.homeDirectory = "/home/spiceratops/";

    myHome.shell.git = {
      enable = true;
      username = "spiceratops";
      email = "141093654+spiceratops@users.noreply.github.com";
      # signingKey = ""; # TODO setup signing keys n shit
    };


    # services.gpg-agent.pinentryPackage = pkgs.pinentry-qt;
    systemd.user.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      ZDOTDIR = "$HOME/.config/zsh";
    };

    home = {
      # Install these packages for my user
      packages = with pkgs; [
        eza
        htop
        unzip
      ];

      sessionVariables = {
        # Workaround for alacritty (breaks wezterm and other apps!)
        # LIBGL_ALWAYS_SOFTWARE = "1";
        EDITOR = "nvim";
        VISUAL = "nvim";
        ZDOTDIR = "$HOME/.config/zsh";
      };

    };

  };
}
