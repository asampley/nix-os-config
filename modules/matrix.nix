{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.matrix = with lib; {
    tuwunel = {
      enable = lib.mkEnableOption "tuwunel matrix server";
      domainName = lib.mkOption {
        type = types.str;
        default = "matrix.${config.my.matrix.tuwunel.publicDomainName}";
      };
      publicDomainName = lib.mkOption {
        type = types.str;
      };
    };
  };

  config =
    let
      cfg = config.my.matrix;
    in
    {
      services.matrix-tuwunel = lib.mkIf cfg.tuwunel.enable {
        enable = true;
        settings.global = {
          server_name = "${cfg.tuwunel.publicDomainName}";
          port = [ 8008 ];
          allow_federation = false;
          allow_registration = true;
          registration_token_file = "/etc/tuwunel/.reg_token";
        };
      };

      services.nginx.virtualHosts."${cfg.tuwunel.publicDomainName}" =
        lib.mkIf (cfg.tuwunel.publicDomainName != null)
          {
            addSSL = true;
            enableACME = true;
            locations = {
              "= /.well-known/matrix/server" = {
                extraConfig = ''
                  add_header Access-Control-Allow-Origin *;
                  default_type application/json;
                '';
                return = "200 '{\"m.server\": \"${cfg.tuwunel.domainName}:443\"}'";
              };

              "= /.well-known/matrix/client" = {
                extraConfig = ''
                  add_header Access-Control-Allow-Origin *;
                  default_type application/json;
                '';
                return = "200 '{\"m.homeserver\": {\"base_url\": \"https://${cfg.tuwunel.domainName}\"}}'";
              };
            };
          };

      services.nginx.virtualHosts."${cfg.tuwunel.domainName}" =
        lib.mkIf (cfg.tuwunel.domainName != null)
          {
            enableACME = true;
            onlySSL = true;
            locations = {
              "/" = {
                proxyPass = "http://localhost:${builtins.toString (builtins.elemAt config.services.matrix-tuwunel.settings.global.port 0)}";
                recommendedProxySettings = true;
              };
            };
          };
    };
}
