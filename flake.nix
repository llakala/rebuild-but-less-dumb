{
  description = "A flake to export my custom rebuild script, Rebuild But Less Dumb (RBLD)";

  inputs.myLib =
  {
    url = "github:llakala/llakaLib";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... } @ inputs:
  let
    # My custom lib functions, declared in another repo so I can use them across projects
    myLib = inputs.myLib.lib;

  in
  {
    packages = myLib.forAllSystems
    (
      pkgs: myLib.collectDirectoryPackages
      {
        inherit pkgs;
        directory = ./packages;
      }
    );

    devShells = myLib.forAllSystems (pkgs:
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
