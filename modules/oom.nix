
# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, ... }:

{
  options.my.oom = {
    enable = lib.mkEnableOption "Enable early oom service";
  };

  config = let cfg = config.my.oom; in lib.mkIf cfg.enable {
    services.earlyoom = {
      enable = true;
      enableNotifications = true;
      freeMemThreshold = 10;
      freeSwapThreshold = 10;
      extraArgs = [
        "--prefer" "(rust-analyzer|firefox|chromium)"
      ];
    };
  };
}
