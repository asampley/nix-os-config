{
  config,
  lib,
  ...
}:
{
  options.my.http-file-share = {
    enable = lib.mkEnableOption "share files with http";

    serverName =
      with config.services.avahi;
      lib.mkOption {
        type = lib.types.str;
        default = "${hostName}.${domainName}";
      };
  };

  config =
    let
      cfg = config.my.http-file-share;
    in
    lib.mkIf cfg.enable {
      # Local host for downloading files
      services.nginx = {
        enable = lib.mkDefault true;

        virtualHosts."${cfg.serverName}" = {
          serverAliases = [
            "localhost"
            "127.0.0.1"
          ];

          locations."/fileshare" = {
            root = "/var/www/";

            tryFiles = "$uri $uri/ =404";

            extraConfig = ''
              autoindex on;
            '';
          };
        };
      };
    };
}
