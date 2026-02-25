{ lib, ... }:
{
  flake.nixosModules.prometheus =
    { config, ... }:
    {
      options.my.monitoring.prometheus = {
        enable = lib.mkEnableOption "prometheus server";
        openFirewall = lib.mkEnableOption "open firewall for access through http";
      };

      config =
        let
          cfg = config.my.monitoring.prometheus;
        in
        lib.mkIf cfg.enable {
          services.prometheus = {
            enable = true;
            globalConfig = {
              scrape_interval = "1m";
            };
            scrapeConfigs = [
              {
                job_name = "self";
                static_configs = [
                  {
                    targets = [ "localhost:${toString config.services.prometheus.exporters.node.port}" ];
                  }
                ];
              }
            ];
            alertmanagers = lib.mkIf config.services.prometheus.alertmanager.enable [
              {
                static_configs = [
                  {
                    targets = [ "localhost:${toString config.services.prometheus.alertmanager.port}" ];
                  }
                ];
              }
            ];
            rules = [
              ''
                groups:
                - name: asampley
                  rules:
                  - alert: LowRootSpace
                    expr: node_filesystem_avail_bytes{mountpoint="/"} / node_filesystem_size_bytes < 0.1
                    annotations:
                      summary: Low disk space on root partition
              ''
            ];
          };

          networking.firewall.allowedTCPPorts = lib.optionals cfg.openFirewall [
            config.services.prometheus.port
          ];
        };
    };

  flake.nixosModules.prometheus-node =
    { config, ... }:
    {
      options.my.monitoring.prometheus-node = with lib; {
        enable = mkEnableOption "prometheus node";
      };

      config = lib.mkIf config.my.monitoring.prometheus-node.enable {
        services.prometheus.exporters.node = {
          enable = true;
          enabledCollectors = [

          ];

          extraFlags = [
            "--collector.systemd.unit-include=borgbackup-job-*\\.(service|timer)"
          ];
        };
      };
    };

  flake.nixosModules.prometheus-ntfy =
    { config, ... }:
    {
      options.my.monitoring.prometheus.ntfy = with lib; {
        enable = mkEnableOption "send notifcations through ntfy";
        baseurl = mkOption {
          type = types.str;
        };
      };

      config =
        let
          cfg = config.my.monitoring.prometheus.ntfy;
        in
        lib.mkIf cfg.enable {
          sops.secrets.alertmanager-ntfy = { };

          services.prometheus = {
            alertmanager-ntfy = {
              enable = true;
              settings = {
                http.addr = "127.0.0.1:9089";
                ntfy = {
                  baseurl = cfg.baseurl;
                  notification.topic = "system";
                };
              };
              extraConfigFiles = [ config.sops.secrets.alertmanager-ntfy.path ];
            };
            alertmanager = {
              enable = true;
              configuration = {
                route = {
                  receiver = "alertmanager-ntfy";
                };
                receivers = [
                  {
                    name = "alertmanager-ntfy";
                    webhook_configs = [
                      {
                        url = "http://${config.services.prometheus.alertmanager-ntfy.settings.http.addr}/hook";
                      }
                    ];
                  }
                ];
              };
            };
          };
        };
    };
}
