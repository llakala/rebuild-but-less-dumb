{ pkgs, self, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    jq
    git
  ];

  selfDeps = with self.packages.${pkgs.system};
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
  text = builtins.readFile ./scripts/fuiska.sh;

}
