{
  config,
  lib,
  ...
}:

{
  options.my.development = {
    enable = lib.mkEnableOption "development service";
  };

  config = lib.mkIf config.my.development.enable {
    nix.settings = {
      keep-outputs = true;
      keep-derivations = true;
    };

    # Enable container options such as registries
    virtualisation.containers.enable = true;

    programs.adb.enable = true;
  };
}
