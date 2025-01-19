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
  name = "fuiska";
  runtimeInputs = nixpkgsDeps ++ selfDeps;

  text = builtins.readFile ./fuiska.fish;

}
