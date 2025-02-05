{ pkgs, llakaLib, lib, localPackages, ... }:

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

in
assert lib.assertMsg (pkgs ? nixos-rebuild-ng)
''
RBLD relies on nixos-rebuild-ng, but it wasn't found in pkgs.
This likely means you made Menu follow nixpkgs 24.11, which doesn't have nixos-rebuild-ng.
Instead, have Menu follow nixpkgs-unstable.
'';
llakaLib.writeFishApplication
{
  name = "rbld"; # Rebuild But Less Dumb
  runtimeInputs = nixpkgsDeps ++ selfDeps;

  text = builtins.readFile ./rbld.fish;
}
