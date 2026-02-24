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
          authentication-file = mkOption {
            type = nullOr str;
            description = "path containing authentication string for curl with ntfy";
            default = null;
          };

        };
      };
    };
  ntfy-command =
    { config, pkgs, ... }:
    topic: prefix: status:
    let
      cfg = config.my.notifications;
    in
    ''
      ${pkgs.curl}/bin/curl '${cfg.ntfy.address}/${topic}' -d '${prefix} '"''$(${pkgs.coreutils}/bin/uname -n): $1 service ${status}." ${
        if (cfg.ntfy.authentication-file != null) then
          ''-u "$(cat "${cfg.ntfy.authentication-file}")"''
        else
          ""
      }
    '';
  ntfy-client-sops =
    { config, ... }:
    {
      options.my.notifications.ntfy = with lib; {
        sops = mkEnableOption "ntfy password management with sops";
      };

      config = lib.mkIf config.my.notifications.ntfy.enable {
        sops.secrets."ntfy/auth" = { };
        my.notifications.ntfy.authentication-file = config.sops.secrets."ntfy/auth".path;
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
      config =
        let
          cfg = config.my.notifications;
        in
        lib.mkMerge [
          (lib.mkIf cfg.libnotify.enable {
            my.notifications.on-failure.script = ''${self'.packages.notify-send-all}/bin/notify-send-all "$1 service failed." --urgency critical;'';
            my.notifications.on-success.script = ''${self'.packages.notify-send-all}/bin/notify-send-all "$1 service succeeded.";'';
          })
          (lib.mkIf cfg.ntfy.enable {
            my.notifications.on-failure.script = ntfy-command { inherit config pkgs; } "system" "🔴" "failed";
            my.notifications.on-success.script = ntfy-command { inherit config pkgs; } "system" "🟢" "succeeded";
          })
          {
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
        ];
    }
  );

  flake.homeModules.notifications =
    { config, pkgs, ... }:
    {
      options = shared-options;
      config =
        let
          cfg = config.my.notifications;
        in
        lib.mkMerge [
          (lib.mkIf cfg.libnotify.enable {
            my.notifications.on-failure.script = lib.mkIf cfg.libnotify.enable ''${pkgs.libnotify}/bin/notify-send "$1 service failed." --urgency critical;'';
            my.notifications.on-success.script = lib.mkIf cfg.libnotify.enable ''${pkgs.libnotify}/bin/notify-send "$1 service succeeded.";'';
          })
          (lib.mkIf cfg.ntfy.enable {
            my.notifications.on-failure.script = ntfy-command { inherit config pkgs; } "home" "🔴" "failed";
            my.notifications.on-success.script = ntfy-command { inherit config pkgs; } "home" "🟢" "succeeded";
          })
          {
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
        ];
    };

  flake.nixosModules.ntfy-client-sops = ntfy-client-sops;
  flake.homeModules.ntfy-client-sops = ntfy-client-sops;

  flake.nixosModules.ntfy-server =
    { config, ... }:
    {
      options.my.ntfy = with lib; {
        enable = mkEnableOption "ntfy server";
        base-url = mkOption {
          type = types.str;
          description = options.services.settings.base-url;
        };
        environmentFiles = mkOption {
          type = types.listOf types.path;
          description = "environment files for the systemd service, useful for managing secrets";
          default = [ ];
        };
        openFirewall = mkEnableOption "ntfy server ports through firewall";
      };

      config =
        let
          cfg = config.my.ntfy;
        in
        lib.mkIf cfg.enable {
          services.ntfy-sh = {
            enable = true;
            settings = {
              base-url = cfg.base-url;
              listen-http = ":2586";
              auth-default-access = "deny-all";
              auth-access = [
                "publish:*:wo"
                "asampley:system:ro"
                "asampley:*:rw"
              ];
              behind-proxy = true;
            };
          };

          networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [ 2586 ];

          systemd.services.ntfy-sh.serviceConfig = {
            EnvironmentFile = cfg.environmentFiles;
          };
        };
    };

  flake.nixosModules.ntfy-server-sops =
    { config, ... }:
    {
      options.my.ntfy.sops = with lib; {
        enable = mkEnableOption "ntfy password management with sops";
      };

      config = lib.mkIf config.my.ntfy.sops.enable {
        sops.secrets."ntfy/environment" = {
          restartUnits = [ "ntfy-sh.service" ];
        };
        my.ntfy.environmentFiles = [ config.sops.secrets."ntfy/environment".path ];
      };
    };
}
