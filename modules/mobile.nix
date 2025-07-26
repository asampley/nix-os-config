{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.mobile = {
    enable = lib.mkEnableOption "mobile tools";
  };

  config = lib.mkIf config.my.mobile.enable {
    environment.systemPackages = with pkgs; [
      jmtpfs
    ];
  };
}
