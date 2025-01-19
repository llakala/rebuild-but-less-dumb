{ pkgs, rbld, hue, llakaLib, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    git
    jq
    nix
    bash
  ];

  selfDeps =
  [
    rbld
    hue
  ];
in llakaLib.writeFishApplication
{
  name = "unify";
  runtimeInputs = nixpkgsDeps ++ selfDeps;

  text = builtins.readFile ./unify.fish;
}
