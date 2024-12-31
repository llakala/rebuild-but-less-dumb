{
  description = "A flake to export my custom rebuild script, Rebuild But Less Dumb (RBLD)";

  outputs = { self, nixpkgs }:
  let
    forAllSystems = function:
      nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed
      (system: function nixpkgs.legacyPackages.${system});

    selfPackagesFromDirectoryRecursive = { directory, pkgs }:
    nixpkgs.lib.makeScope pkgs.newScope
    (
      self: nixpkgs.lib.packagesFromDirectoryRecursive
      {
        inherit (self) callPackage;
        inherit directory;
      }
    );

  in
  {
    packages = forAllSystems
    (
      pkgs: selfPackagesFromDirectoryRecursive
      {
        inherit pkgs;
        directory = ./packages;
      }
    );

    devShells = forAllSystems (pkgs:
    {
      default = pkgs.mkShell
      {
        packages = with self.packages.${pkgs.system};
        [
          rbld
          unify
          hue # You don't need to install this manually, it's a dependency of the others. I just use install it manually for debugging
          fuiska
        ];
      };
    });

  };
}
