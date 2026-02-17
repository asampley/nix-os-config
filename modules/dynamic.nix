{
  flake.nixosModules.dynamic =
    {
      config,
      lib,
      ...
    }:
    {
      options.my.dynamic = {
        enable = lib.mkEnableOption "dynamic linking helpers";
      };

      config = lib.mkIf config.my.dynamic.enable {
        programs.nix-ld.enable = true;
      };
    };
}
