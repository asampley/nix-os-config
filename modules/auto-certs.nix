{ config, lib, options, ... }:
{
  options.my.auto-certs = {
    enable = lib.mkEnableOption "auto generate certs using ACME";

    defaults = options.security.acme.defaults;
  };

  config = let cfg = config.my.auto-certs; in lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;

      defaults = cfg.defaults;

      certs = let hosts = config.services.nginx.virtualHosts; in builtins.listToAttrs (
        map (name: { inherit name; value = {}; }) (
          builtins.filter (name: hosts."${name}".enableACME == true) (
            builtins.attrNames hosts
          )
        )
      );
    };
  };
}
