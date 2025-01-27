{ pkgs, llakaLib, localPackages, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    git
    jq
    nix
    bash
  ];

  selfDeps = with localPackages;
  [
    rbld
    hue
    revive
  ];

in llakaLib.writeFishApplication
{
  name = "unify"; # Update NixOS Inputs For Yourself
  runtimeInputs = nixpkgsDeps ++ selfDeps;

  text = builtins.readFile ./unify.fish;
}
