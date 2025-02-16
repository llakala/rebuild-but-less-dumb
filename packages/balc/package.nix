{ pkgs, llakaLib, ... }:

llakaLib.writeFishApplication
{
  name = "balc"; # Be A Little Careful
  runtimeInputs = with pkgs;
  [
    jq
    lix
  ];

  text = builtins.readFile ./balc.fish;
}
