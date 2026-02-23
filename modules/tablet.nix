{ moduleWithSystem, ... }:
{
  perSystem =
    { self', pkgs, ... }:
    {
      packages = {
        accel-rotation = pkgs.writeShellScriptBin "accel-rotation" ''

          set -eu
          ACCEL_DISPLAY=$1
          X=$(cat $ACCEL_DISPLAY/in_accel_x_raw)
          Y=$(cat $ACCEL_DISPLAY/in_accel_y_raw)
          if [ $X -gt 0 ]; then
            if [ $Y -gt 0 ]; then
              if [ $Y -gt $X ]; then R=0; else R=270; fi
            else
              if [ $Y -lt -$X ]; then R=180; else R=270; fi
            fi
          else
            if [ $Y -gt 0 ]; then
              if [ -$Y -lt $X ]; then R=0; else R=270; fi
            else
              if [ $Y -lt $X ]; then R=180; else R=270; fi
            fi
          fi

          echo "$R"
        '';

        niri-accel-rotate = pkgs.writeShellScriptBin "niri-accel-rotate" ''
          set -eu
          ACCEL_DISPLAY=$1
          niri msg output eDP-1 transform "$(${self'.packages.accel-rotation}/bin/accel-rotation "$ACCEL_DISPLAY" | sed 's/^0$/normal/')"
        '';

        niri-accel-auto-rotate = pkgs.writeShellScriptBin "niri-accel-auto-rotate" ''
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
                ExecStart = "${self'.packages.niri-accel-auto-rotate}/bin/niri-accel-auto-rotate";
              };
            };
          };
        };
    }
  );
}
