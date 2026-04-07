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
      url = "github:heytcass/claude-desktop-linux-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # OpenClaw community skill: self-improving-agent
    # Vendored as a flake input (no Nix in-repo) — referenced as a
    # source tree by programs.openclaw.skills in home/programs/openclaw.
    openclaw-skill-self-improving-agent = {
      url = "github:peterskoett/self-improving-agent";
      flake = false;
    };

  };

  outputs = { self, nixpkgs, home-manager, nixvim, sops-nix, claude-code, claude-desktop, lanzaboote, yandex-browser, nix-openclaw, openclaw-skill-self-improving-agent, ... }@inputs:
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
            (import ./overlays/argocd-fix.nix)
            (import ./overlays/hyprland-plugins-fix.nix)
            nix-openclaw.overlays.default
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
