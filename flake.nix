{
  description                                       = "Siquery";

  inputs                                            = {
    systems.url                                     = "path:./flake.systems.nix";
    systems.flake                                   = false;

    nixpkgs.url                                     = "github:NixOS/nixpkgs/23.11";

    flake-utils.url                                 = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows              = "systems";

    rust-overlay.url                                = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows             = "nixpkgs";
    rust-overlay.inputs.flake-utils.follows         = "flake-utils";

    flake-compat.url                                = "github:edolstra/flake-compat";
    flake-compat.flake                              = false;

    cargo2nix.url                                   = "github:cargo2nix/cargo2nix/release-0.11.0";
    cargo2nix.inputs.nixpkgs.follows                = "nixpkgs";
    cargo2nix.inputs.rust-overlay.follows           = "rust-overlay";
    cargo2nix.inputs.flake-utils.follows            = "flake-utils";
    cargo2nix.inputs.flake-compat.follows           = "flake-compat";
  };

  outputs                                           = {
    nixpkgs,
    flake-utils,
    cargo2nix,
    ...
  }:
    let
      mkPkgs                                        =
        system:
          pkgs: (
            # NixPkgs
            import pkgs {
              inherit system;
              overlays                              = [cargo2nix.overlays.default];
            }
            //
            # Custom Packages.
            {
            }
          );
    in (
      flake-utils.lib.eachDefaultSystem (system: (
        let
          pkgs                                      = mkPkgs system nixpkgs;
          pkgsRust                                  = pkgs.rustBuilder.makePackageSet {
            rustVersion                             = "1.75.0";
            packageFun                              = import ./Cargo.nix;
            workspaceSrc                            = ./.;
          };
          manifest                                  = (pkgs.lib.importTOML ./siquery_cli/Cargo.toml).package;
          environment                               = {
            inherit pkgs;
            inherit pkgsRust;
            inherit manifest;
          };
          name                                      = manifest.name;
        in rec {
          packages.${name}                          = (pkgsRust.workspace.${name} {});
          legacyPackages                            = packages;

          # `nix build`
          defaultPackage                            = packages.${name};

          # `nix run`
          apps.${name}                              = flake-utils.lib.mkApp {
            inherit name;
            drv                                     = packages.${name};
          };
          defaultApp                                = apps.${name};

          # `nix develop`
          devShells.${system}.default               = import ./shell.nix environment;
        })));
}

