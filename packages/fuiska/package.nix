{ pkgs, llakaLib, hue, fight, ... }:

let
  nixpkgsDeps = with pkgs;
  [
    jq
    git
  ];

  selfDeps =
  [
    hue
    fight
  ];

in llakaLib.writeFishApplication
{
  name = "fuiska"; # Flake Updates I Should Know About?
  runtimeInputs = nixpkgsDeps ++ selfDeps;

  text = builtins.readFile ./fuiska.fish;

}
