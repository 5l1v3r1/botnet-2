{ config, pkgs, lib, ... }:

{

  networking.firewall.allowedTCPPorts = [ 1337 ];

  services.nginx = {
    enable = true;
    virtualHosts = {};
    appendHttpConfig = ''
      server {
        listen *:1337;
        access_log ${config.services.nginx.stateDir}/logs/cc.log;
        return 200 'foo
        ';
      }
    '';
  };

}
