{pkgs, ...}:
with pkgs;
  stdenv.mkDerivation {
    name = "nix-live-derivation";
    src = builtins.path {
      path = ./.;
      name = "source";
    };
    buildInputs = [
      odin
    ];
    buildPhase = ''
      odin build . -o:speed -out:nix-live-derivation
    '';
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp nix-live-derivation $out/bin
      runHook postInstall
    '';
  }
