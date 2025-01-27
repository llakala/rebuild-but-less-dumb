{ pkgs, llakaLib, ... }:

llakaLib.writeFishApplication
{
  name = "fight"; # Flake Input Gets Hash Tested
  runtimeInputs = with pkgs;
  [
    git
    jq
  ];

  text = builtins.readFile ./fight.fish;
}
