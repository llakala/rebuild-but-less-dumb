{ pkgs, hue, llakaLib, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    jq
    git
    parallel
  ];

  selfDeps =
  [
    hue
  ];

in llakaLib.writeFishApplication
{
  name = "fuiska"; # Flake Updates I Should Know About?
  runtimeInputs = nixpkgsDeps ++ selfDeps;

  text = builtins.readFile ./fuiska.fish;

}
