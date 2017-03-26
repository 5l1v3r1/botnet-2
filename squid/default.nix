{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.squid;

  configFile = pkgs.writeText "squid.conf" ''
    http_port ${toString cfg.proxyPort}

    access_log daemon:${cfg.logDir}/access.log squid
    cache_log ${cfg.logDir}/cache.log squid
    pid_filename ${cfg.stateDir}/pid
    cache_effective_user ${cfg.user}

    ${cfg.extraConfig}
  '';

in

{

  ###### interface

  options = {

    services.squid = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable squid.
        '';
      };

      user = mkOption {
        type = types.str;
        default = "squid";
        description = ''
          Effective squid user.
        '';
      };

      port = mkOption {
        type = types.int;
        default = 3128;
        description = ''
          The port that squid listens on.
        '';
      };

      stateDir = mkOption {
        type = types.path;
        default = "/run/squid";
        description = ''
          State directory for squid.
        '';
      };

      logDir = mkOption {
        type = types.path;
        default = "/var/log/squid";
        description = ''
          Log directory for squid.
        '';
      };

      extraConfig = mkOption {
        type = types.path;
        example = literalExample ''pkgs.writeText "squid.conf" "# my custom config file ..."'';
        description = ''
          See the source.
        '';
      };

    };

  };

  ###### implementation

  config = mkIf cfg.enable {

    users.extraUsers = optionalAttrs (cfg.user == "squid") (singleton
      { name = "squid";
        group = mainCfg.group;
        description = "Squid user";
        uid = config.ids.uids.squid;
      });

    users.extraGroups = optionalAttrs (cfg.user == "squid") (singleton
      { name = "squid";
        gid = config.ids.gids.squid;
      });

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
        mkdir -p ${cfg.stateDir}
        mkdir -p ${cfg.logDir}
        chown ${cfg.user} ${cfg.stateDir}
        chown ${cfg.user} ${cfg.logDir}
      '';

    };

  };

}
