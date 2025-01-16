{ pkgs, hue, writeShellApplication, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    jq
    git
  ];

  selfDeps =
  [
    hue
  ];

in writeShellApplication
{
  name = "fuiska";
  runtimeInputs = nixpkgsDeps ++ selfDeps;
  bashOptions =
  [
    "nounset" # -u
    "errexit" # -e
    "pipefail"
    "errtrace" # -E
  ];
  text = builtins.readFile ./fuiska.sh;

}
