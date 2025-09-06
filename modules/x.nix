{
  config,
  lib,
  ...
}:

{
  options.my.x = {
    enable = lib.mkEnableOption "x11 window manager and settings";
  };

  config = let cfg = config.my.x; in lib.mkIf cfg.enable {
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # We must have one window manager available at least, let's keep it minimal.
    #
    # This helps us debug our home-manager instance to make sure awesome is independent from system.
    services.xserver.windowManager.openbox.enable = true;
  };
}
