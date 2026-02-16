# Function to return fetcher derivation based on JSON data
{
  pkgs,
  fetcherString,
}: let
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
  fetcher
