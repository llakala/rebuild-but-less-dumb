{
  description = "A flake to export my custom rebuild script, Rebuild But Less Dumb (RBLD)";

  outputs = { self, nixpkgs }:
  let
    forAllSystems = function:
      nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
      (system: function nixpkgs.legacyPackages.${system});

  in
  {
    packages = forAllSystems (pkgs:
    {
      default = pkgs.callPackage ./default.nix { };
    });

    devShells = forAllSystems (pkgs:
    {
      default = pkgs.mkShell
      {
        packages = [ self.packages.${pkgs.system}.default ];
      };
    });

  };
}
