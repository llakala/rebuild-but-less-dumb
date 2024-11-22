{ pkgs, self, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    nix-output-monitor # aka nom
    nixos-rebuild
    git
  ];

  selfDeps = with self.packages.${pkgs.system};
  [
    hue
  ];
in pkgs.writeShellApplication
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
  text = builtins.readFile ./scripts/rbld.sh;
}
