# Override existing package with fetcher
# Returns new package derivation
{
  pkgs,
  package,
  gitString,
  nixLiveDerivation,
}: let
  getFetcher = import ./get-fetcher.nix;
  newSrcText = pkgs.writeScript "get-new-source.sh" ''
    ${nixLiveDerivation}/bin/nix-live-derivation ${gitString}
  '';
  newSrc = builtins.fromJSON newSrcText;
  fetcher = getFetcher newSrc.fetcher;
in
  package.overrideAttrs (_: _: {
    src = fetcher {
      owner = newSrc.owner;
      repo = newSrc.repo;
      rev = newSrc.rev;
      sha256 = newSrc.sha256;    };
  })

