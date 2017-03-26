{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.quarantine;

in {

  ###### interface

  options = {

    services.quarantine = {

      user = mkOption {
        type = types.str;
        description = ''
          Owner of quarantine.
        '';
      };

      dir = mkOption {
        type = types.path;
        default = "/var/quarantine";
        description = ''
          Quarantine directory.
        '';
      };

    };

  };

  ###### implementation

  config = mkIf cfg.enable {

    systemd.services.quarantine = {
      description = "Quarantine";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "idle";
        ExecStart = "${pkgs.coreutils}/bin/true";
      };

      preStart = ''
        [ -d ${cfg.dir} ] && rm -r ${cfg.dir}
        mkdir -p ${cfg.dir}
        chown ${cfg.user} ${cfg.dir}
        cp ${./htaccess} ${cfg.dir}/.htaccess
      '';

    };

  };

}
