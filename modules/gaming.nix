{
  flake.nixosModules.gaming =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.my.gaming = {
        enable = lib.mkEnableOption "gaming service";
      };

      config = lib.mkIf config.my.gaming.enable {
        programs.steam = {
          enable = true;
          remotePlay.openFirewall = true;
          dedicatedServer.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
        };

        # List packages installed in system profile. To search, run:
        environment.systemPackages = with pkgs; [
          steam-run
          vulkan-tools
        ];
      };
    };
}
