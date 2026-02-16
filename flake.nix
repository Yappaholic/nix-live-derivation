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
        nixLiveDerivation = pkgs.callPackage ./pkg/default.nix {inherit pkgs;};
        mkLive = package: gitString:
          pkgs.callPackage ./nix/mklive.nix {
            pkgs = pkgs;
            package = package;
            gitString = gitString;
            nixLiveDerivation = nixLiveDerivation;
          };
      in {
        lib = {
          mkLive = mkLive;
        };
        checks = {
          get-derivation-info = pkgs.runCommand "get-derivation-info" {} ''
            ${nixLiveDerivation}/bin/nix-live-derivation "github:Yappaholic/nix-live-derivation" > $out
            echo "All good" > $out
          '';
        };
        packages = rec {
          nix-live-derivation = nixLiveDerivation;
          default = nix-live-derivation;
        };
      }
    );
}
