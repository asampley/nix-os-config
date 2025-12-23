{
  config,
  lib,
  ...
}:

{
  options.my.maintenance = {
    enable = lib.mkEnableOption "automatic maintenance tasks";
  };

  config = lib.mkIf config.my.maintenance.enable {
    nix.gc = {
      options = "--delete-older-than 30d";
    };

    system.autoUpgrade = {
      enable = lib.mkDefault true;
      dates = lib.mkDefault "Mon *-*-* 00:00:00";
      runGarbageCollection = lib.mkDefault true;
      randomizedDelaySec = lib.mkDefault "0min";
      persistent = lib.mkDefault true;
      flake = lib.mkDefault "/etc/nixos";
      flags = [
        "-L"
      ] ++ lib.optionals (config.system.autoUpgrade.flake != null) [
        "--update-input"
        "nixpkgs"
      ];
    };

  };
}
