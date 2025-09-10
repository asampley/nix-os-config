# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  # Custom modules
  my.auto-certs.enable = true;
  my.development.enable = true;
  my.dynamic.enable = true;
  #my.emulation.enable = true;
  my.gaming.enable = true;
  my.http-file-share.enable = true;
  my.mobile.enable = true;
  my.nextcloud.enable = true;
  my.noise-reduce.enable = true;
  my.wayland.enable = true;
  my.x.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "amanda"; # Define your hostname.

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
    persistent = true;
    randomizedDelaySec = "45min";
  };

  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    randomizedDelaySec = "45min";
  };

  # enable userspace oom killer
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
  };

  # enable real-time kit for audio
  security.rtkit.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  programs.slock.enable = true;
  programs.firefox.enable = true;

  environment.systemPackages = with pkgs; [
    alsa-utils
    pwvucontrol
    vulkan-tools
  ];

  services.avahi.publish = {
    enable = true;
    addresses = true;
    userServices = true;
  };

  services.earlyoom = {
    enable = true;
    enableNotifications = true;
    freeMemThreshold = 10;
    freeSwapThreshold = 10;
    extraArgs = [
      "--prefer" "(firefox|chromium)"
    ];
  };

  my.nextcloud.hostName = "cloud.asampley.ca";
  my.nextcloud.https = true;

  services.nginx.virtualHosts."${config.services.nextcloud.hostName}" = {
    enableACME = true;
  };

  services.borgbackup.jobs.nextcloud = let cfgnc = config.services.nextcloud; in {
    paths = [ cfgnc.datadir ];
    repo = "fm2515@fm2515.rsync.net:backup/nextcloud";

    readWritePaths = [ "${cfgnc.datadir}" ];

    privateTmp = true;

    preHook = ''
      # Lock nextcloud files for consistency
      ${cfgnc.occ}/bin/nextcloud-occ maintenance:mode --on

      # Backup database while locked
      ${config.security.sudo.package}/bin/sudo -u nextcloud ${config.services.postgresql.package}/bin/pg_dump -U ${cfgnc.config.dbuser} ${cfgnc.config.dbname} -f /tmp/pg_dump.sql
    '';

    postHook = ''
      # Unlock nextcloud files
      ${cfgnc.occ}/bin/nextcloud-occ maintenance:mode --off
    '';

    environment = {
      BORG_RSH = "ssh -i /root/.ssh/id_ed25519 ";
      BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
    };

    startAt = "*-*-* *:00:00";
    persistentTimer = true;

    encryption = {
      mode = "repokey";
      passCommand = "cat /root/borg.pass";
    };
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
