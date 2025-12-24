{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
      };
      mkSystems = builtins.mapAttrs (
        name: value:
        nixpkgs.lib.nixosSystem {
          system = value.system;

          specialArgs = {
            inherit inputs;
          };
          modules = [
            {
              nixpkgs.overlays = [
                inputs.nix-alien.overlays.default
              ];
            }
            ./hosts/${name}/configuration.nix
          ];
        }
      );
    in
    {
      nixosConfigurations = mkSystems hostInfo;
      formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" ] (
        system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );
    };
}
