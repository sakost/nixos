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

    yandex-browser = {
      url = "github:sakost/nix-yandex-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    android-nixpkgs = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, nixvim, sops-nix, claude-code, claude-desktop, lanzaboote, yandex-browser, android-nixpkgs, ... }@inputs:
  let
    system = "x86_64-linux";

    theme = import ./lib/theme.nix;

    # Helper function to create a NixOS system configuration
    mkHost = hostname: nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs hostname theme; };
      modules = [
        ./hosts/${hostname}
        sops-nix.nixosModules.sops
        lanzaboote.nixosModules.lanzaboote
        home-manager.nixosModules.home-manager
        { nixpkgs.overlays = [
            android-nixpkgs.overlays.default
            (import ./overlays/argocd-fix.nix)
          ];
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs theme; };
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
