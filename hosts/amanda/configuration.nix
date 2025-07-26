# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

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

  # enable real-time kit for audio
  security.rtkit.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # We must have one window manager available at least, let's keep it minimal.
  #
  # This helps us debug our home-manager instance to make sure awesome is independent from system.
  services.xserver.windowManager.openbox.enable = true;
  #services.xserver.windowManager.awesome = {
  #  enable = true;
  #  luaModules = with pkgs.luaPackages; [
  #    luarocks
  #  ];
  #};

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
}
