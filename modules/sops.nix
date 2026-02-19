{ lib, ... }:
{
  flake.nixosModules.sops =
    { config, pkgs, ... }:
    {
      options.my.sops = with lib; {
        enable = mkEnableOption "sops secret management";
      };

      config =
        let
          cfg = config.my.sops;
        in
        lib.mkIf cfg.enable {
          environment.systemPackages = with pkgs; [
            sops
            (writeShellScriptBin "sops-edit" ''
              export SOPS_AGE_KEY_CMD="${ssh-to-age}/bin/ssh-to-age -private-key -i '${builtins.elemAt config.sops.age.sshKeyPaths 0}'"
              ${sops}/bin/sops edit ${config.sops.defaultSopsFile}
            '')
          ];
          sops.defaultSopsFile = "/root/sops/secrets/main.yaml";
          sops.validateSopsFiles = false;
          sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
        };
    };
}
