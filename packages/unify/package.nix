{ pkgs, rbld, hue, writeShellApplication, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    git
    jq
    nix
    bash
  ];

  selfDeps =
  [
    rbld
    hue
  ];
in writeShellApplication
{
  name = "unify";
  runtimeInputs = nixpkgsDeps ++ selfDeps;
  excludeShellChecks = # Shellcheck checks to ignore. ex: "SC2016"
  [

  ];
  bashOptions =
  [
    "nounset" # -u
    "errexit" # -e
    "pipefail"
    "errtrace" # -E
  ];
  text = builtins.readFile ./unify.sh;
}
