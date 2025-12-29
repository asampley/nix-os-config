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
      services.postgresql = {
        enable = true;

        ensureDatabases = [ "utf_nate" ];
        ensureUsers = [
          {
            name = "utf_nate";
            ensureDBOwnership = true;
          }
        ];

        initialScript = pkgs.writeText "init-nextcloud-script" ''
          GRANT ALL PRIVILEGES ON DATABASE utf_nate TO utf_nate;
        '';
      };

      systemd.services."utf-nate@" = {
        description = "UTF-Nate discord bot";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        restartIfChanged = true;
        serviceConfig = {
          ExecStart = "${inputs.utf-nate.packages.${pkgs.stdenv.hostPlatform.system}.utf-nate}/bin/utf-nate";
          PrivateTmp = true;
          WorkingDirectory = "/etc/utf-nate/%u";
        };
      };
    };
}
