{
  description = "NixOS configuration with Home Manager - Multi-host flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixvim, sops-nix, claude-code, ... }@inputs:
  let
    system = "x86_64-linux";

    # Helper function to create a NixOS system configuration
    mkHost = hostname: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs hostname; };
      modules = [
        ./hosts/${hostname}
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users.sakost = import ./home/sakost.nix;
          };
        }
      ];
    };
  in {
    nixosConfigurations = {
      # Current portable/temp disk setup
      sakost-pc-portable = mkHost "sakost-pc-portable";

      # Future main PC with 2x NVMe (placeholder)
      sakost-pc = mkHost "sakost-pc";
    };
  };
}
