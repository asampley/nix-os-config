{
  flake.homeModules.gui =
    {
      lib,
      pkgs,
      ...
    }:
    {
      config = {
        home.packages = with pkgs; [
          bitwarden-desktop
          chromium
          dconf
          dex
          discord
          firefox
          gnome-network-displays
          inkscape
          kdePackages.kdenlive
          libreoffice
          mpv
          qbittorrent
          thunar
          xournalpp
        ];

        programs.alacritty = {
          enable = true;
        };

        programs.obs-studio = {
          enable = true;
          plugins = [
            pkgs.obs-studio-plugins.obs-pipewire-audio-capture
          ];
        };

        dconf.settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = lib.mkForce "prefer-dark";
          };
        };

        fonts.fontconfig.enable = true;
      };
    };
}
