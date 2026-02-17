{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.my.cloud = with lib; {
    nextcloud = {
      enable = mkEnableOption "host nextcloud instance";

      hostName = mkOption {
        type = types.str;
        default = "${config.services.avahi.hostName}.${config.services.avahi.domainName}";
      };

      borgbackup = {
        enable = mkEnableOption "borg backups of nextcloud";
        name = mkOption {
          type = types.str;
          default = "nextcloud";
        };
      };

      https = lib.mkEnableOption "https for nextcloud";
    };
  };

  config =
    let
      cfg = config.my.cloud;
    in
    lib.mkMerge [
      (lib.mkIf cfg.nextcloud.enable {
        services.nextcloud = {
          enable = true;

          https = cfg.nextcloud.https;

          package = pkgs.nextcloud32;
          hostName = "${cfg.nextcloud.hostName}";

          extraAppsEnable = true;
          extraApps = with config.services.nextcloud.package.packages.apps; {
            inherit
              contacts
              calendar
              news
              notes
              tasks
              ;
          };

          config = {
            adminpassFile = "/etc/nextcloud-admin-pass";
            dbtype = "pgsql";
            dbname = "nextcloud";
            dbuser = "nextcloud";
            dbhost = "/run/postgresql";
          };

          settings = {
            log_type = "systemd";
          };
        };

        systemd.services.nextcloud-custom-config = {
          path = [
            config.services.nextcloud.occ
          ];
          script = ''
            nextcloud-occ theming:config url "https://${cfg.nextcloud.hostName}";
          '';
          after = [ "nextcloud-setup.service" ];
          wantedBy = [ "multi-user.target" ];
        };

        services.nginx.virtualHosts."${cfg.nextcloud.hostName}" = {
          enableACME = cfg.nextcloud.https;
          forceSSL = cfg.nextcloud.https;
        };

        networking.firewall.allowedTCPPorts = lib.optionals cfg.nextcloud.https [
          443
          80
        ];

        services.postgresql = {
          enable = true;

          ensureDatabases = [ "nextcloud" ];
          ensureUsers = [
            {
              name = "nextcloud";
              ensureDBOwnership = true;
            }
          ];
        };

        systemd.services."nextcloud-setup" = {
          requires = [ "postgresql.service" ];
          after = [ "postgresql.service" ];
        };

        services.borgbackup.jobs = lib.mkIf cfg.nextcloud.borgbackup.enable {
          "${cfg.nextcloud.borgbackup.name}" =
            let
              cfgnc = config.services.nextcloud;
            in
            {
              paths = [
                cfgnc.datadir
                "/tmp/output"
              ];

              readWritePaths = [ "${cfgnc.datadir}" ];

              privateTmp = true;

              preHook = ''
                # Make directory for additional outputs
                ${pkgs.coreutils}/bin/mkdir -m 777 /tmp/output/

                # Lock nextcloud files for consistency
                ${cfgnc.occ}/bin/nextcloud-occ maintenance:mode --on

                # Backup database while locked
                ${config.security.sudo.package}/bin/sudo -u nextcloud ${config.services.postgresql.package}/bin/pg_dump -U ${cfgnc.config.dbuser} ${cfgnc.config.dbname} -f /tmp/output/pg_dump.sql
              '';

              postHook = ''
                # Unlock nextcloud files
                ${cfgnc.occ}/bin/nextcloud-occ maintenance:mode --off
              '';

              startAt = lib.mkDefault "*-*-* *:00:00";
              persistentTimer = lib.mkDefault true;
            };
        };
      })
    ];
}
