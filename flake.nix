{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    utf-nate = {
      url = "github:asampley/UTF-Nate";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-alien.url = "github:thiagokokada/nix-alien";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      hostInfo = {
        "amanda" = {
          system = "x86_64-linux";
        };
        "miranda" = {
          system = "x86_64-linux";
        };
        "willheim" = {
          system = "x86_64-linux";
        };
      };
      # Leave out nix-alien to keep its own nixpkgs
      mkSystems = builtins.mapAttrs (
        name: value:
        nixpkgs.lib.nixosSystem {
          system = value.system;

          specialArgs = {
            inherit inputs;
          };
          modules = [
            ./hosts/${name}/configuration.nix
            {
              nixpkgs.overlays = [
                (final: prev: {
                  utf-nate = inputs.utf-nate.packages.${prev.stdenv.hostPlatform.system}.default;
                })
              ];
            }
          ];
        }
      );
    in
    {
      nixosConfigurations = mkSystems hostInfo;
      formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (
        system: nixpkgs.legacyPackages.${system}.nixfmt
      );
    };
}
