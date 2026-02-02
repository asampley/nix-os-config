{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./audio.nix
    ./auto-certs.nix
    ./bluetooth.nix
    ./development.nix
    ./dynamic.nix
    ./emulation.nix
    ./gaming.nix
    ./http-file-share.nix
    ./maintenance.nix
    ./mobile.nix
    ./nextcloud.nix
    ./noise-reduce.nix
    ./oom.nix
    ./power-saving.nix
    ./utf-nate.nix
    ./x.nix
    ./wayland.nix
  ];

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
    extraGroups = [
      "wheel"
      "plugdev"
    ]
    ++ lib.optional config.services.nginx.enable "nginx"
    ++ lib.optional config.virtualisation.docker.enable "docker";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGDHPkbNhmExKEsUQ9gn+IzYzRhnG49Q+rwZ/S+mascf asampley@amanda"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDDtgero+Wbw7kq/5t8ylM+tUnRh1o0ca1jTrh9r32PS asampley@miranda"
    ];
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "hplip"
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
    git
    inputs.nix-alien.packages.${pkgs.stdenv.hostPlatform.system}.nix-alien
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

  services.rsnapshot = {
    extraConfig = ''
      retain hourly 24
      retain daily 365
      retain monthly 12
      retain yearly 10
    '';
    cronIntervals = {
      hourly = "0 * * * *";
      daily = "1 0 * * *";
      monthly = "2 0 1 * *";
      yearly = "3 0 1 1 *";
    };
  };

  # Default virtual host to block unknown server names.
  services.nginx.virtualHosts."_" = {
    default = true;
    extraConfig = "return 404;";
  };

  services.libinput.touchpad = {
    clickMethod = "clickfinger";
  };

  programs.ssh.knownHosts = {
    "fm2515.rsync.net" = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINdUkGe6kKn5ssz4WRZKjcws0InbQqZayenzk9obmP1z";
    };
  };

  hardware.steam-hardware.enable = true;
}
