{
  description = "A flake to export my custom rebuild script, Rebuild But Less Dumb (RBLD)";

  outputs = { self, nixpkgs }:
  let
    lib = nixpkgs.lib;
    forAllSystems = lib.genAttrs lib.systems.flakeExposed;
  in
  {
    packages = forAllSystems (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      default = import ./default.nix { inherit pkgs; };
    }
    );
  };
}