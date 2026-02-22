{ moduleWithSystem, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        niri-accel-rotate = pkgs.writeShellScriptBin "niri-accel-rotate" ''
          ${pkgs.iio-sensor-proxy}/bin/monitor-sensor --accel\
            | ${pkgs.gnused}/bin/sed -u -n '
              /Accelerometer orientation changed/!d;
              s/.*:\s*//;
              s/left-up/90/; s/inverted/180/; s/right-up/270/;
              p'\
            | while read rotation; do
                niri msg output eDP-1 transform "$rotation"
              done
        '';
      };
    };

  flake.homeModules.tablet = moduleWithSystem (
    { self', ... }:
    { config, lib, ... }:
    {
      options.my.tablet = with lib; {
        niri = mkEnableOption "enable niri tablet tools";
      };

      config =
        let
          cfg = config.my.tablet;
        in
        {
          systemd.user.services = {
            niri-rotate = lib.mkIf cfg.niri {
              Unit = {
                Description = "accelerometer detecting screen rotation";
                After = [ "niri.service" ];
                PartOf = [ "niri.service" ];
              };

              Install = {
                WantedBy = [ "niri.service" ];
              };

              Service = {
                ExecStart = "${self'.packages.niri-accel-rotate}/bin/niri-accel-rotate";
              };
            };
          };
        };
    }
  );
}
