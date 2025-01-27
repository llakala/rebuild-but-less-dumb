{ pkgs, llakaLib, localPackages, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    nix-output-monitor # aka nom
    nixos-rebuild
    git
  ];

  selfDeps = with localPackages;
  [
    hue
  ];

in llakaLib.writeFishApplication
{
  name = "rbld"; # Rebuild But Less Dumb
  runtimeInputs = nixpkgsDeps ++ selfDeps;

  text = builtins.readFile ./rbld.fish;
}
