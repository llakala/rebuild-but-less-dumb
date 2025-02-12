{ pkgs, llakaLib, ... }:

llakaLib.writeFishApplication
{
  name = "fight"; # Flake Input Gets Hash Tested
  runtimeInputs = with pkgs;
  [
    git
    jq
    dateutils
  ];

  text = builtins.readFile ./fight.fish;
}
