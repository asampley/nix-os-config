{ lib, ... }:
{
  flake.nixosModules.sops =
    { config, ... }:
    {
      options.my.sops = with lib; {
        enable = mkEnableOption "sops secret management";
      };

      config =
        let
          cfg = config.my.sops;
        in
        lib.mkIf cfg.enable {
          sops.defaultSopsFile = "/root/sops/secrets/main.yaml";
          sops.age = {
            sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
            keyFile = "/var/lib/sops-nix/key.txt";
            generateKey = true;
          };
        };
    };
}
