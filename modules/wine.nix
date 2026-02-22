{
  flake.homeModules.wine =
    { pkgs, ... }:
    {
      config = {
        home.packages = with pkgs; [
          (wineWow64Packages.full.override {
            wineRelease = "staging";
            mingwSupport = true;
          })
          winetricks
        ];
      };
    };
}
