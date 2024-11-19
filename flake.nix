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
      rbld = pkgs.callPackage ./rbld.nix { };
      unify = pkgs.callPackage ./unify.nix { }; 
      hue = pkgs.callPackage ./hue.nix { };
    });

    devShells = forAllSystems (pkgs:
    {
      default = pkgs.mkShell
      {
        packages = with self.packages.${pkgs.system};
        [ 
          rbld
          unify
          hue
        ];
      };
    });

  };
}
