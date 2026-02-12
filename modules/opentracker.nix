{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.opentracker = {
    enable = lib.mkEnableOption "opentracker service";
    openFirewall = lib.mkEnableOption "open ports used by opentracker in the firewall";
    supportReverseProxy = lib.mkEnableOption "allow opentracker to work with a reverse proxy";
  };

  config =
    let
      cfg = config.my.opentracker;
    in
    lib.mkIf cfg.enable {
      services.opentracker = {
        enable = true;
        package = pkgs.opentracker.overrideAttrs (
          final: prev: {
            # allows setting up a reverse proxy
            makeFlags =
              prev.makeFlags ++ lib.optionals cfg.supportReverseProxy [ "FEATURES=-DWANT_IP_FROM_PROXY" ];
          }
        );
        # allows setting up a reverse proxy
        extraOptions = "-f ${
          pkgs.writeText "opentracker-config" (
            lib.strings.concatLines (lib.optionals cfg.supportReverseProxy [ "access.proxy 127.0.0.1" ])
          )
        }";
      };

      networking.firewall = {
        allowedTCPPorts = lib.optionals cfg.openFirewall [ 6969 ];
        allowedUDPPorts = lib.optionals cfg.openFirewall [ 6969 ];
      };
    };
}
