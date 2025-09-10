{
  config,
  lib,
  pkgs,
  ...
}: {
  options.my.nextcloud = {
    enable = lib.mkEnableOption "host nextcloud instance";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "${config.services.avahi.hostName}.${config.services.avahi.domainName}";
    };

    https = lib.mkEnableOption "https for nextcloud";
  };

  config = let
    cfg = config.my.nextcloud;
  in lib.mkIf cfg.enable {
    services.nextcloud = {
      enable = true;

      https = cfg.https;

      package = pkgs.nextcloud31;
      hostName = "${cfg.hostName}";

      extraAppsEnable = true;
      extraApps = with config.services.nextcloud.package.packages.apps; {
        inherit contacts calendar news notes tasks;
      };

      config = {
        adminpassFile = "/etc/nextcloud-admin-pass";
        dbtype = "pgsql";
        dbname = "nextcloud";
        dbuser = "nextcloud";
        dbhost = "/run/postgresql";
      };
    };

    services.nginx.virtualHosts."${cfg.hostName}" = {
      forceSSL = cfg.https;
    };

    networking.firewall.allowedTCPPorts = lib.optionals cfg.https [ 443 80 ];

    services.postgresql = {
      enable = true;

      ensureDatabases = [ "nextcloud" ];
      ensureUsers = [
        {
          name = "nextcloud";
          ensureDBOwnership = true;
        }
      ];

      initialScript = pkgs.writeText "init-nextcloud-script" ''
        GRANT ALL PRIVILEGES ON DATABASE nextcloud TO nextcloud;
        GRANT ALL PRIVILEGES ON SCHEMA public TO nextcloud;
      '';
    };

    systemd.services."nextcloud-setup" = {
      requires = [ "postgresql.service" ];
      after = [ "postgresql.service" ];
    };
  };
}
