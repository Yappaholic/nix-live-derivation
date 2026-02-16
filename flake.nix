{
  description = "Nix-live-derivation is a way to get package sources from HEAD";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        packages = rec {
          nix-live-derivation = pkgs.callPackage ./pkg/default.nix {inherit pkgs;};
          default = nix-live-derivation;
        };
      }
    );
}
