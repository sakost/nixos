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
      # Pinned to last-working rev: upstream HEAD's patches fail against
      # Claude Desktop 1.8555.2 (minified JS restructured). Unpin once fixed.
      url = "github:heytcass/claude-desktop-linux-flake/7e2abbc77eba594638528d900968da6579959d66";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # git-ai — tracks AI-generated code attribution via git notes
    git-ai = {
      url = "github:git-ai-project/git-ai";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, nixvim, sops-nix, claude-code, claude-desktop, lanzaboote, yandex-browser, ... }@inputs:
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
          ];
        }
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            # Back up (don't fail on) pre-existing unmanaged files on rebuild.
            # Clean up with `find ~ -name '*.hm-backup' -delete`.
            backupFileExtension = "hm-backup";
            extraSpecialArgs = { inherit inputs theme; };
            users.sakost = import ./home/sakost.nix;
          };
        }
      ];
    };
  in {
    nixosConfigurations = {
      sakost-pc = mkHost "sakost-pc";
    };
  };
}
