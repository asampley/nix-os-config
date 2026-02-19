{ self, withSystem, ... }:
{
  flake.nixosConfigurations.willheim = withSystem "x86_64-linux" (
    { inputs', ... }:
    self.inputs.nixpkgs.lib.nixosSystem {
      modules = builtins.attrValues self.nixosModules ++ [
        self.inputs.sops-nix.nixosModules.sops
        (
          { config, ... }:
          {
            imports = [
              ./hardware-configuration.nix
            ];

            # Custom modules
            my.auto-certs.enable = true;
            my.maintenance.enable = true;
            my.matrix.tuwunel = {
              enable = true;
              publicDomainName = "asampley.ca";
              sops.enable = true;
            };
            my.cloud.nextcloud = {
              enable = true;
              hostName = "cloud.asampley.ca";
              https = true;
              borgbackup.enable = true;
              sops.enable = true;
            };
            my.bittorrent.opentracker = {
              enable = true;
              supportReverseProxy = true;
            };
            my.sops.enable = true;
            my.utf-nate.enable = true;

            # Use the systemd-boot EFI boot loader.
            boot.loader.systemd-boot.enable = true;
            boot.loader.efi.canTouchEfiVariables = true;

            system.autoUpgrade = {
              allowReboot = true;
              rebootWindow = {
                lower = "02:00";
                upper = "03:00";
              };
            };

            networking.hostName = "willheim"; # Define your hostname.

            # Enable CUPS to print documents.
            # services.printing.enable = true;

            services.avahi.publish = {
              enable = true;
              addresses = true;
              userServices = true;
            };

            services.openssh = {
              enable = true;
              settings = {
                PasswordAuthentication = false;
                KbdInteractiveAuthentication = false;
              };
            };

            services.nginx.virtualHosts."tracker.asampley.ca" = {
              onlySSL = true;
              enableACME = true;
              locations."/" = {
                proxyPass = "http://localhost:6969/announce";
                recommendedProxySettings = true;
              };
            };

            services.rsnapshot.extraConfig = ''
              # Valheim server
              #backup /home/steam/.config/unity3d/IronGate/Valheim/worlds_local/	localhost/	exclude=*_backup_*,exclude=*.old
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

            environment.etc."utf-nate/1/resources".source = "${inputs'.utf-nate.packages.utf-nate}/resources";
            environment.etc."utf-nate/2/resources".source = "${inputs'.utf-nate.packages.utf-nate}/resources";

            systemd.targets.multi-user.wants = [
              "utf-nate@1.service"
              "utf-nate@2.service"
            ];

            sops.secrets.borg-pass = { };

            services.borgbackup.jobs."${config.my.cloud.nextcloud.borgbackup.name}" = {
              repo = "ssh://fm2515@fm2515.rsync.net/./backup/nextcloud";

              environment = {
                BORG_RSH = "ssh -i /etc/ssh/ssh_host_ed25519_key";
                BORG_REMOTE_PATH = "/usr/local/bin/borg1/borg1";
              };

              encryption = {
                mode = "repokey";
                passCommand = "cat ${config.sops.secrets.borg-pass.path}";
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
        )
      ];
    }
  );
}
