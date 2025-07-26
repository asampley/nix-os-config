{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      hostInfo = {
        "amanda" = {
          system = "x86_64-linux";
        };
        "meili" = {
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
