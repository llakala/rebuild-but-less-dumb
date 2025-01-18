{ pkgs, llakaLib, ... }:

llakaLib.writeFishApplication
{
  name = "hue";
  runtimeInputs = with pkgs;
  [
    git
    nix
  ];
  text = builtins.readFile ./hue.fish;
}
