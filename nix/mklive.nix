# Override existing package with fetcher
# Returns new package derivation
{
  pkgs,
  package,
  gitString,
  nixLiveDerivation,
}: let
  newSrcText = pkgs.runCommand "get-new-source" {} ''
    ${nixLiveDerivation}/bin/nix-live-derivation ${gitString}
  '';
  newSrc = builtins.fromJSON newSrcText;
  fetcher = import ./get-fetcher.nix {
    inherit pkgs;
    fetcherString = newSrc.fetcher;
  };
in
  package.overrideAttrs (_: _: {
    src = fetcher {
      owner = newSrc.owner;
      repo = newSrc.repo;
      rev = newSrc.rev;
      sha256 = newSrc.sha256;
    };
  })
