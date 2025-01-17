{
  description = "A flake to export my custom rebuild script, Rebuild But Less Dumb (RBLD)";

  inputs.llakaLib =
  {
    url = "github:llakala/llakaLib";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, ... } @ inputs:
  let
    lib = nixpkgs.lib;

    # The "normal" systems. If it ever doesn't work with one of these, or you want me
    # to add a system, let me know!
    supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64_linux" "aarch64-darwin" ];

    forAllSystems = function: lib.genAttrs
      supportedSystems
      (system: function nixpkgs.legacyPackages.${system});

    # My custom lib functions, declared in another repo so I can use them across projects
    # Some of them require `pkgs`, so this function gives you a `llakaLib` instance from
    # `fullLib`, which includes system-dependent functions.
    mkLlakaLib = system: inputs.llakaLib.fullLib.${system};

  in
  {
    packages = forAllSystems
    (
      pkgs: let llakaLib = mkLlakaLib pkgs.system;
      in llakaLib.collectDirectoryPackages
      {
        inherit pkgs;
        directory = ./packages;

        extras = { inherit llakaLib; }; # Lets the packages rely on llakaLib
      }
    );

    devShells = forAllSystems
    (pkgs:
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
      }
    );

  };
}
