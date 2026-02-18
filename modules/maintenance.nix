{
  flake.nixosModules.maintenance =
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
          randomizedDelaySec = lib.mkDefault "0m";
          persistent = lib.mkDefault true;
          flake = lib.mkDefault "/etc/nixos";
          flags = [
            "-L"
          ]
          ++ lib.optionals (config.system.autoUpgrade.flake != null) [
            "--recreate-lock-file"
          ];
        };

        systemd.services.nixos-upgrade = {
          unitConfig = {
            OnSuccess = [ "notify-on-success@nixos-upgrade.service" ];
            OnFailure = [ "notify-on-failure@nixos-upgrade.service" ];
          };

          serviceConfig = {
            # Retry just in case network conditions are bad (e.g. hibernation)
            Restart = "on-failure";
            RestartSec = "1m";
            RestartSteps = "10";
            RestartMaxDelaySec = "1h";
          };
        };
      };
    };
}
