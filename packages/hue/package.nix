{ pkgs, writeShellApplication, ... }:

writeShellApplication
{
  name = "hue";
  runtimeInputs = with pkgs;
  [
    git
    nix
  ];
  bashOptions =
  [
    "nounset" # -u
    "errexit" # -e
    "pipefail"
    "errtrace" # -E
  ];
  text = builtins.readFile ./hue.sh;

}
