# Build a compiler from a GHC source tree.
#

# ghcTree: path to a GHC source tree
{ ghcTree }: pkgs:

let
  base = pkgs.callPackage "${pkgs.path}/pkgs/development/compilers/ghc/head.nix" rec {
    bootPkgs = pkgs.haskell.packages.ghc843;
    inherit (bootPkgs) alex happy hscolour;
    buildLlvmPackages = pkgs.buildPackages.llvmPackages_6;
    llvmPackages = pkgs.llvmPackages_6;
    version = "8.6.0";
  };
in base.overrideAttrs (oldAttrs: {
  src = with pkgs.lib; cleanSourceWith {
    src = ghcTree;
    filter = name: type: cleanSourceFilter name type
      && ! hasSuffix "are-validating.mk" name
      && ! hasSuffix "_build" name;
  };
})
