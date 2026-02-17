{
  inputs = {
    systems = {
      url = ./systems.nix;
      flake = false;
    };

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    utf-nate = {
      url = "github:asampley/UTF-Nate";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien.url = "github:thiagokokada/nix-alien";
  };

  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (top: {
      imports = [
        (inputs.import-tree ./modules)
        #(((inputs.import-tree.map inputs.nixpkgs.lib.traceVal).filter (p: inputs.nixpkgs.lib.baseNameOf p == "hardware-configuration.nix")) ./hosts)
        ./hosts/amanda/configuration.nix
        ./hosts/miranda/configuration.nix
        ./hosts/willheim/configuration.nix
      ];
      systems = import ./systems.nix;
      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt;
        };
    });
}
