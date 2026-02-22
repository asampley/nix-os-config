{ lib, ... }:
{
  flake.nixosModules.x =
    {
      config,
      ...
    }:
    {
      options.my.x = {
        enable = lib.mkEnableOption "x11 window manager and settings";
      };

      config =
        let
          cfg = config.my.x;
        in
        lib.mkIf cfg.enable {
          # Enable the X11 windowing system.
          services.xserver.enable = true;

          # x server locking tool
          programs.slock.enable = true;

          # We must have one window manager available at least, let's keep it minimal.
          #
          # This helps us debug our home-manager instance to make sure awesome is independent from system.
          services.xserver.windowManager.openbox.enable = true;
        };
    };

  flake.homeModules.x =
    {
      config,
      pkgs,
      ...
    }:
    {
      config = {
        home.packages = with pkgs; [
          awesome
          scrot
          xclip
          xss-lock
        ];

        home.file = {
          ".xsession".source = ../files/.xsession;
          ".xinitrc".source = ../files/.xinitrc;
        };

        xdg.configFile = {
          "awesome".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/home-manager/files/.config/awesome";
        };

        systemd.user.services.xautolock-session = {
          Unit = {
            Description = "xautolock, session locker service";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
            # do not start if running under wayland
            ConditionEnvironment = "!WAYLAND_DISPLAY";
          };

          Install = {
            WantedBy = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = lib.concatStringsSep " " [
              "${pkgs.xautolock}/bin/xautolock"
              "-time 10"
              "-locker '${pkgs.systemd}/bin/loginctl lock-session \${XDG_SESSION_ID}'"
              "-detectsleep"
              "-corners -0-0"
            ];
            Restart = "always";
          };
        };
      };
    };
}
