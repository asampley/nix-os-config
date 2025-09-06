{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./auto-certs.nix
    ./development.nix
    ./dynamic.nix
    ./emulation.nix
    ./gaming.nix
    ./http-file-share.nix
    ./mobile.nix
    ./nextcloud.nix
    ./noise-reduce.nix
    ./x.nix
    ./wayland.nix
  ];

  system.autoUpgrade = {
    persistent = lib.mkDefault true;
    flake = lib.mkDefault "/etc/nixos";
    flags = [
      "-L"
    ] ++ lib.optionals (config.system.autoUpgrade.flake != null) [
      "--update-input"
      "nixpkgs"
    ];
  };

  time.timeZone = lib.mkDefault "Canada/Mountain";

  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = lib.mkDefault true; # Easiest to use and most distros use this by default.

  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Don't forget to set a password with ‘passwd’.
  users.users.asampley = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]
      ++ lib.optional config.services.nginx.enable "nginx"
      ++ lib.optional config.virtualisation.docker.enable "docker"
      ++ lib.optional config.programs.adb.enable "adbusers"
    ;
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
      "nvidia-x11"
      "nvidia-settings"
      "nvidia-persistenced"
    ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    wget
  ];

  services.avahi = {
    # Enable avahi to discover local services
    enable = true;
    # Enable transparent query to avahi daemon
    nssmdns4 = true;
  };

  # Allow users to specify allow_other or allow_root on fuse mounts
  programs.fuse.userAllowOther = true;

  my.auto-certs.defaults.email = "alex.sampley@gmail.com";

  # Default virtual host to block unknown server names.
  services.nginx.virtualHosts."_" = {
    default = true;
    extraConfig = "return 404;";
  };
}
