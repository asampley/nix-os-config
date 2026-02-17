{
  flake.nixosModules.wayland =
    {
      config,
      lib,
      ...
    }:
    {
      options.my.wayland = {
        enable = lib.mkEnableOption "wayland window manager and settings";
      };

      config =
        let
          cfg = config.my.wayland;
        in
        lib.mkIf cfg.enable {
          # Make sure we use a wayland supported display manager
          services.displayManager.gdm.enable = true;

          # Window manager which I haven't found a way yet to use home-manager
          programs.niri.enable = true;
        };
    };
}
