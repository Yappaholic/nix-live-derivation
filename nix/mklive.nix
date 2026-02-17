# Override existing package with fetcher
# Returns new package derivation
{
  pkgs,
  package,
  gitString,
  nixLiveDerivation,
}: let
  newSrcText = pkgs.runCommand "get-new-source" {} ''
    mkdir -p $out
    ${nixLiveDerivation}/bin/nix-live-derivation ${gitString} > $out/live-derivation-info.json
  '';
  newSrc = builtins.fromJSON (builtins.readFile "${newSrcText}/live-derivation-info.json");
  fetcherString = newSrc.fetcher;
  fetcher =
    if fetcherString == "fetchFromGitHub"
    then pkgs.fetchFromGitHub
    else if fetcherString == "fetchFromSourcehut"
    then pkgs.fetchFromSourcehut
    else if fetcherString == "fetchFromBitBucket"
    then pkgs.fetchFromBitBucket
    else if fetcherString == "fetchFromGitLab"
    then pkgs.fetchFromGitLab
    else if fetcherString == "fetchGit"
    then pkgs.fetchgit
    else throw "Unexpected fetcher type";
in
  package.overrideAttrs (_: _: {
    version = "git";
    src = fetcher {
      owner = newSrc.owner;
      repo = newSrc.repo;
      rev = newSrc.rev;
      sha256 = newSrc.sha256;
    };
  })
