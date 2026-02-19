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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (top: {
      imports = [
        (inputs.import-tree ./modules)
        ((inputs.import-tree.filter (p: inputs.nixpkgs.lib.baseNameOf p != "hardware-configuration.nix"))
          ./hosts
        )
      ];
      systems = import ./systems.nix;
      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt;
        };
    });
}
