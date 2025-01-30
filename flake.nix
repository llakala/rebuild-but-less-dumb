{
  # Menu stands for: My Excellent NixOS Utils
  description = "Menu, a collection of NixOS utilities.";

  inputs =
  {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    llakaLib =
    {
      url = "github:llakala/llakaLib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... } @ inputs:
  let
    lib = nixpkgs.lib;

    # The "normal" systems. If it ever doesn't work with one of these, or you want me
    # to add a system, let me know!
    supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

    forAllSystems = function: lib.genAttrs
      supportedSystems
      (system: function nixpkgs.legacyPackages.${system});
  in
  {
    legacyPackages = forAllSystems
    (
      pkgs: let llakaLib = inputs.llakaLib.fullLib.${pkgs.system};
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
          packages = with self.legacyPackages.${pkgs.system};
          [
            rbld
            unify
            fuiska

            # Internal dependencies of the other commands, added to the devshell for debugging
            hue
            fight
            revive
          ];
        };
      }
    );

  };
}
