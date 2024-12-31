{ pkgs, hue, ... }:

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

in pkgs.writeShellApplication
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
