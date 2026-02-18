{ lib, moduleWithSystem, ... }:
let
  shared-options =
    with lib;
    with types;
    {
      my.notifications = {
        enable = mkEnableOption "add notify-on-success and notify-on-failure systemd services";
        on-failure = {
          script = mkOption {
            type = lines;
            description = "script to run on tasks with this failure task assigned";
            example = "\${pkgs.libnotify}/bin/notify-send \"$1 failed\"";
            default = "";
          };
        };
        on-success = {
          script = mkOption {
            type = lines;
            description = "script to run on tasks with this failure task assigned";
            example = "\${pkgs.libnotify}/bin/notify-send \"$1 succeeded\"";
            default = "";
          };
        };
        libnotify = {
          enable = mkEnableOption "use libnotify to notify on the desktop";
        };
        ntfy = {
          enable = mkEnableOption "send curl requests to ntfy.sh service";
          address = mkOption {
            type = str;
            description = "address to send requests to";
            example = "willheim.local";
          };
        };
      };
    };
  shared-config =
    { config, pkgs, ... }:
    let
      cfg = config.my.notifications;
    in
    {
      my.notifications = {
        on-failure.script = lib.strings.concatLines (
          [ ]
          ++ lib.optional cfg.ntfy.enable ''${pkgs.curl}/bin/curl '${cfg.ntfy.address}'/"$1" -d '${config.networking.hostName}'": $1 service failed."''
        );
        on-success.script = lib.strings.concatLines (
          [ ]
          ++ lib.optional cfg.ntfy.enable ''${pkgs.curl}/bin/curl '${cfg.ntfy.address}'/"$1" -d '${config.networking.hostName}'": $1 service succeeded."''
        );
      };
    };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        notify-send-all =
          with pkgs;
          writeShellScriptBin "notify-send-all" ''
            for BUS in /run/user/*/bus; do
              USER_ID=''${BUS#/run/user/}
              USER_ID=''${USER_ID%/bus}
              ${sudo}/bin/sudo -u "#$USER_ID" DBUS_SESSION_BUS_ADDRESS=unix:path="$BUS" ${libnotify}/bin/notify-send "$@"
            done

            exit 0
          '';
      };
    };

  flake.nixosModules.notifications = moduleWithSystem (
    { self', ... }:
    { config, pkgs, ... }:
    {
      options = shared-options;
      config = lib.mkMerge [
        (shared-config { inherit config pkgs; })
        (
          let
            cfg = config.my.notifications;
          in
          {
            my.notifications.on-failure.script = lib.mkIf cfg.libnotify.enable ''${self'.packages.notify-send-all}/bin/notify-send-all "$1 service failed." --urgency critical;'';
            my.notifications.on-success.script = lib.mkIf cfg.libnotify.enable ''${self'.packages.notify-send-all}/bin/notify-send-all "$1 service succeeded.";'';

            systemd.services = lib.mkIf cfg.enable {
              "notify-on-failure@" = {
                unitConfig.Description = "runs a script notifying %i has failed";
                serviceConfig.ExecStart = "${pkgs.writeShellScript "on-failure" cfg.on-failure.script} %i";
              };
              "notify-on-success@" = {
                unitConfig.Description = "runs a script notifying %i has succeeded";
                serviceConfig.ExecStart = "${pkgs.writeShellScript "on-success" cfg.on-success.script} %i";
              };
            };
          }
        )
      ];
    }
  );

  flake.homeModules.notifications =
    { config, pkgs, ... }:
    {
      options = shared-options;
      config = lib.mkMerge [
        (shared-config { inherit config pkgs; })
        (
          let
            cfg = config.my.notifications;
          in
          {
            my.notifications.on-failure.script = lib.mkIf cfg.libnotify.enable ''${pkgs.libnotify}/bin/notify-send "$1 service failed." --urgency critical;'';
            my.notifications.on-success.script = lib.mkIf cfg.libnotify.enable ''${pkgs.libnotify}/bin/notify-send "$1 service succeeded.";'';

            systemd.user.services = lib.mkIf cfg.enable {
              "notify-on-failure@" = {
                Unit.Description = "runs a script notifying %i has failed";
                Service.ExecStart = "${pkgs.writeShellScript "on-failure" cfg.on-failure.script} %i";
              };
              "notify-on-success@" = {
                Unit.Description = "runs a script notifying %i has succeeded";
                Service.ExecStart = "${pkgs.writeShellScript "on-success" cfg.on-success.script} %i";
              };
            };
          }
        )
      ];
    };
}
