{ config, lib, ... }:
{
  options = {
    flyingcircus.roles.antivirus = {
      enable = lib.mkEnableOption "ClamAV antivirus scanner";
    };
  };

  config = lib.mkIf config.flyingcircus.roles.antivirus.enable {
    flyingcircus.services.clamav.daemon.enable = true;
    flyingcircus.services.clamav.updater.enable = true;
  };
}
