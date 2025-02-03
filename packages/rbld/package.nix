{ pkgs, llakaLib, localPackages, ... }:

let
  lixos-rebuild-ng = pkgs.nixos-rebuild-ng.override
  {
    nix = pkgs.lix;
  };
  nixpkgsDeps = with pkgs;
  [
    nix-output-monitor # aka nom
    git
  ] ++ lib.singleton lixos-rebuild-ng;

  selfDeps = with localPackages;
  [
    hue
    revive
  ];

in llakaLib.writeFishApplication
{
  name = "rbld"; # Rebuild But Less Dumb
  runtimeInputs = nixpkgsDeps ++ selfDeps;

  text = builtins.readFile ./rbld.fish;
}
