{ pkgs, self, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    git
    jq
    nix
    bash
  ];

  selfDeps = with self.packages.${pkgs.system};
  [
    rbld
    hue
  ];
in pkgs.writeShellApplication
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
  text = builtins.readFile ./scripts/unify.sh;
}
