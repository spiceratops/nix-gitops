{ lib
, config
, pkgs
, ...
}:
with lib;
let
  cfg = config.mySystem.services.comin;
in
{
  options.mySystem.services.comin.enable = mkEnableOption "comin";

  config = mkIf cfg.enable {

    services.comin = {
      enable = true;
      remotes = [{
        name = "origin";
        url = "https://github.com/spiceratops/nix-gitops";
        branches.main.name = "main";
  }];
  };
  };
}
