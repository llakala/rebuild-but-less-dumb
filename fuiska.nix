{ pkgs, ... }:

pkgs.writeShellApplication
{
  name = "fuiska";
  runtimeInputs = with pkgs;
  [
    git
    jq
  ];
  bashOptions =
  [
    "nounset" # -u
    "errexit" # -e
    "pipefail"
    "errtrace" # -E
  ];
  text = builtins.readFile ./scripts/fuiska.sh;

}
