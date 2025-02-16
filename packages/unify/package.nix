{ pkgs, llakaLib, localPackages, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    git
  ];

  selfDeps = with localPackages;
  [
    rbld
    hue
    revive
    balc
  ];

in llakaLib.writeFishApplication
{
  name = "unify"; # Update NixOS Inputs For Yourself
  runtimeInputs = nixpkgsDeps ++ selfDeps;

  text = builtins.readFile ./unify.fish;
}
