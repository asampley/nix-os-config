{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.prosody = with lib; {
    enable = mkEnableOption "prosody XMPP server";
    domainName = mkOption {
      type = types.str;
      default = "xmpp.${config.my.prosody.publicDomainName}";
    };
    publicDomainName = mkOption {
      type = types.str;
    };
    openFirewall = mkEnableOption "open firewall for basic client server ports";
  };

  config =
    let
      cfg = config.my.prosody;
      sslCertDir = config.security.acme.certs."${cfg.publicDomainName}".directory;
    in
    lib.mkIf cfg.enable {
      networking.firewall = {
        allowedTCPPorts = lib.optionals cfg.openFirewall [
          5222
          5223
        ];
      };

      services.prosody = {
        enable = true;
        admins = [ "asampley@${cfg.publicDomainName}" ];
        allowRegistration = lib.mkDefault false;
        authentication = "internal_plain";
        s2sSecureAuth = lib.mkDefault true;
        s2sRequireEncryption = lib.mkDefault true;
        c2sRequireEncryption = lib.mkDefault true;
        ssl = {
          cert = "${sslCertDir}/fullchain.pem";
          key = "${sslCertDir}/key.pem";
        };
        virtualHosts = {
          "${cfg.publicDomainName}" = {
            domain = "${cfg.publicDomainName}";
            enabled = true;
          };
        };
        modules = {
          admin_adhoc = lib.mkDefault false;
          cloud_notify = lib.mkDefault false;
          blocklist = lib.mkDefault false;
          bookmarks = lib.mkDefault false;
          dialback = lib.mkDefault false;
          ping = lib.mkDefault false;
          private = lib.mkDefault false;
          register = lib.mkDefault false;
          vcard_legacy = lib.mkDefault false;
        };
        muc = [
          {
            domain = "conference.${cfg.domainName}";
            restrictRoomCreation = false;
          }
        ];
        httpFileShare = {
          domain = "upload.${cfg.domainName}";
        };
        disco_items = [
          {
            description = "http file share";
            url = "upload.${cfg.domainName}";
          }
        ];
        xmppComplianceSuite = lib.mkDefault false;
      };

      # certs for xmpp
      security.acme.certs."${cfg.publicDomainName}" = {
        extraDomainNames = [
          "${cfg.domainName}"
          "*.${cfg.domainName}"
        ];
        postRun = ''
          ${pkgs.acl}/bin/setfacl -m u:prosody:rx "${
            config.security.acme.certs.${cfg.publicDomainName}.directory
          }"
          ${pkgs.acl}/bin/setfacl -m u:prosody:r "${
            config.security.acme.certs.${cfg.publicDomainName}.directory
          }"/*.pem
        '';
        reloadServices = [ "prosody" ];
      };

    };
}
