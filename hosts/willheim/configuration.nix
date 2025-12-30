# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules
  ];

  # Custom modules
  my.auto-certs.enable = true;
  my.maintenance.enable = true;
  my.nextcloud = {
    enable = true;
    hostName = "cloud.asampley.ca";
    https = true;
  };
  my.utf-nate.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "willheim"; # Define your hostname.

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  services.avahi.publish = {
    enable = true;
    addresses = true;
    userServices = true;
  };

  networking.firewall.allowedUDPPorts = []
    ++ lib.optionals config.services.opentracker.enable [ 6969 ];

  networking.firewall.allowedTCPPorts = []
    ++ lib.optionals config.services.opentracker.enable [ 6969 ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  services.opentracker.enable = true;
  services.nginx.virtualHosts."tracker.asampley.ca" = {
    locations."/" = {
      proxyPass = "http://127.0.0.1:6969";
    };
  };

  services.rsnapshot.extraConfig = ''
    # Valheim server
    #backup /home/steam/.config/unity3d/IronGate/Valheim/worlds_local/	localhost/	exclud=*_backup_*,exclude=*.old
  '';

  environment.etc."utf-nate/1/config.toml".text = ''
    # List of prefixes recognized by the bot
    prefixes = ["!", "‽"]
    # Status setting of the bot
    activity = { Watching = { name = "you." } }
  '';

  environment.etc."utf-nate/2/config.toml".text = ''
    # List of prefixes recognized by the bot
    prefixes = ["?", "‽"]
    # Status setting of the bot
    activity = { Watching = { name = "\U0001F440" } }
  '';

  environment.etc."utf-nate/1/resources".source = "${pkgs.utf-nate}/resources";
  environment.etc."utf-nate/2/resources".source = "${pkgs.utf-nate}/resources";

  systemd.targets.multi-user.wants = [
    "utf-nate@1.service"
    "utf-nate@2.service"
  ];

  services.borgbackup.jobs.nextcloud =
    let
      cfgnc = config.services.nextcloud;
    in
    {
      paths = [ cfgnc.datadir "/tmp/output" ];
      repo = "ssh://fm2515@fm2515.rsync.net/./backup/nextcloud";

      readWritePaths = [ "${cfgnc.datadir}" ];

      privateTmp = true;

      preHook = ''
        # Make directory for additional outputs
        ${pkgs.coreutils}/bin/mkdir -m 777 /tmp/output/

        # Lock nextcloud files for consistency
        ${cfgnc.occ}/bin/nextcloud-occ maintenance:mode --on

        # Backup database while locked
        ${config.security.sudo.package}/bin/sudo -u nextcloud ${config.services.postgresql.package}/bin/pg_dump -U ${cfgnc.config.dbuser} ${cfgnc.config.dbname} -f /tmp/output/pg_dump.sql
      '';

      postHook = ''
        # Unlock nextcloud files
        ${cfgnc.occ}/bin/nextcloud-occ maintenance:mode --off
      '';

      environment = {
        BORG_RSH = "ssh -i /etc/ssh/ssh_host_ed25519_key";
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
  system.stateVersion = "25.11"; # Did you read the comment?
}
