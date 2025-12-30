{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  options.my.utf-nate = {
    enable = lib.mkEnableOption "utfnate options";
  };

  config =
    let
      cfg = config.my.utf-nate;
    in
    lib.mkIf cfg.enable {
      users.users.utf-nate = {
        isSystemUser = true;
        group = "utf-nate";
      };

      users.groups.utf-nate = {};

      services.postgresql = {
        enable = true;

        ensureDatabases = [ "utf-nate" ];
        ensureUsers = [
          {
            name = "utf-nate";
            ensureDBOwnership = true;
          }
        ];

        initialScript = pkgs.writeText "init-utf-nate-script" ''
          GRANT ALL PRIVILEGES ON DATABASE utf-nate TO utf-nate;
        '';
      };

      systemd.services."utf-nate@" = {
        description = "UTF-Nate discord bot";
        after = [ "network.target" ];
        restartIfChanged = true;
        serviceConfig = {
          ExecStart = "${inputs.utf-nate.packages.${pkgs.stdenv.hostPlatform.system}.utf-nate}/bin/utf-nate";
          PrivateTmp = true;
          WorkingDirectory = "/etc/utf-nate/%i";
        };
      };
    };
}
