{
  description = "nnn-starter — an opinionated NixOS starter for the NNN stack (NixOS + Niri + Noctalia)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Scrollable-tiling Wayland compositor + NixOS/home-manager modules.
    # Deliberately does NOT follow our nixpkgs, so niri-flake's prebuilt
    # packages stay byte-identical to what niri.cachix.org has cached.
    niri.url = "github:sodiboo/niri-flake";

    # Noctalia desktop shell (v5 line). Pinned to the `cachix` branch: upstream
    # force-pushes there only after a commit's package is built and pushed to
    # noctalia.cachix.org, so `packages.default` is guaranteed to be a cache hit
    # (no ~hour-long C++ source build). It tracks `main` (v5), just slightly
    # behind. Crucially we do NOT make it follow our nixpkgs — that would
    # rebuild it against a different nixpkgs and miss the cache.
    noctalia.url = "github:noctalia-dev/noctalia-shell/cachix";

    # System-wide base16 theming.
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen browser (not in nixpkgs). It's a repackaged binary (fixed-output
    # download + wrapFirefox), so following our nixpkgs is cheap and avoids a
    # duplicate nixpkgs in the closure.
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      # Its home-manager module reuses HM's firefox module, so share ours.
      inputs.home-manager.follows = "home-manager";
    };

    # OpenLogi (Logitech HID++ companion). Not reliably in nixpkgs on Linux yet,
    # so we take the upstream flake's package + NixOS module (udev + agent).
    # Follow our nixpkgs so the GUI links against the same Wayland/Vulkan as
    # the rest of the desktop; rust-overlay (a nested input) still supplies a
    # new-enough rustc. No binary cache — first switch compiles it from source.
    openlogi = {
      url = "github:AprilNEA/OpenLogi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Age-encrypted secrets in git; decrypted at activation with the SSH host key.
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      # We only use the NixOS module + Linux CLI; skip unused nested inputs.
      inputs.darwin.follows = "";
      inputs.home-manager.follows = "";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    niri,
    noctalia,
    stylix,
    openlogi,
    agenix,
    ...
  } @ inputs: let
    # The platform the NNN machine runs on.
    hostSystem = "x86_64-linux";

    # Personal, machine-local settings. Tracked with placeholder defaults but
    # marked skip-worktree so your real values never get committed:
    #   git update-index --skip-worktree local.nix
    local = import ./local.nix;
    inherit (local) username;

    # Helper so `nix fmt` / `nix develop` work from macOS or Linux.
    devSystems = [
      "x86_64-linux"
      "aarch64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    forAllSystems = nixpkgs.lib.genAttrs devSystems;
    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations.nnn = nixpkgs.lib.nixosSystem {
      system = hostSystem;
      specialArgs = {inherit inputs username local;};
      modules = [
        niri.nixosModules.niri
        noctalia.nixosModules.default
        stylix.nixosModules.stylix
        openlogi.nixosModules.default
        agenix.nixosModules.default
        home-manager.nixosModules.home-manager

        ./hosts/nnn
        ./modules/nixos

        {
          nixpkgs.config.allowUnfree = true;
          # Vesktop builds Vencord with pnpm, which nixpkgs currently marks
          # insecure. It's a build-time tool only; allow it by name so the rule
          # survives pnpm version bumps. (See modules/home/discord.nix.)
          nixpkgs.config.allowInsecurePredicate = pkg: nixpkgs.lib.getName pkg == "pnpm";
          nixpkgs.overlays = [
            niri.overlays.niri
            noctalia.overlays.default
          ];

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-bak";
          home-manager.extraSpecialArgs = {inherit inputs username local;};
          # niri-flake auto-imports its home modules (config + stylix) into
          # every user when home-manager runs as a NixOS module, so we only
          # add noctalia's here. Importing the niri ones again double-declares
          # `programs.niri.finalConfig`.
          home-manager.sharedModules = [
            noctalia.homeModules.default
          ];
          home-manager.users.${username} = import ./modules/home;
        }
      ];
    };

    # `nix fmt`
    formatter = forAllSystems (system: (pkgsFor system).alejandra);

    # `nix develop` — tooling for hacking on this repo.
    devShells = forAllSystems (system: {
      default = (pkgsFor system).mkShell {
        packages = with pkgsFor system; [
          alejandra
          statix
          deadnix
          nh
          nix-output-monitor
          agenix.packages.${system}.default
        ];
      };
    });
  };
}
