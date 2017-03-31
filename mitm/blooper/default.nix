{ bundlerEnv, ruby }:

bundlerEnv {
  inherit ruby;
  name = "blooper";
  gemfile = ./Gemfile;
  lockfile = ./Gemfile.lock;
  gemset = ./gemset.nix;
}
