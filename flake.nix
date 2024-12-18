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
      rbld = pkgs.callPackage ./rbld.nix { inherit self; };
      unify = pkgs.callPackage ./unify.nix { inherit self; };
      hue = pkgs.callPackage ./hue.nix { };
      fuiska = pkgs.callPackage ./fuiska.nix { inherit self; };
    });

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
