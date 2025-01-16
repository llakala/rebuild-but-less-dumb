{ pkgs, hue, writeShellApplication, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    nix-output-monitor # aka nom
    nixos-rebuild
    git
  ];

  selfDeps =
  [
    hue
  ];
in writeShellApplication
{
  name = "rbld";
  runtimeInputs = nixpkgsDeps ++ selfDeps;
  bashOptions =
  [
    "nounset" # -u
    "errexit" # -e
    "pipefail"
    "errtrace" # -E
  ];
  text = builtins.readFile ./rbld.sh;
}
