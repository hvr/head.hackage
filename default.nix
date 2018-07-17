# Build head.hackage packages
#
# Usage:
#   Build using nixpkgs' ghcHEAD:
#       nix build -f ./.
#
#   Build using GHC built from source tree $GHC_TREE:
#       nix build -f --arg ghc "(import build.nix {ghc-path=$GHC_TREE;})"
#
let
  rev = "f2632f5c60f574d787fc5490efb3f43f9e6209b7";
  baseNixpkgs =
    builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    sha256 = "1c36p7w36i38gng3yp1nd5vz0p2dwrax5szjkvnmdxfklggs7knf";
  };
in

# ghc: path to a GHC source tree
{ ghc ? import ./ghc.nix }:

let
  jailbreakOverrides = self: super: {
    mkDerivation = drv: super.mkDerivation (drv // { jailbreak = true; doCheck = false; });
  };

  overrides = self: super: rec {
    all-cabal-hashes = self.fetchurl (import ./all-cabal-hashes.nix);

    # Should this be self?
    ghcHEAD = ghc super;

    haskellPackages =
      let patchesOverrides = self.callPackage patches {};
          patches = self.callPackage (import ./scripts/overrides.nix) { patches = ./patches; };
          overrides = self.lib.composeExtensions patchesOverrides jailbreakOverrides;

          baseHaskellPackages = self.callPackage "${baseNixpkgs}/pkgs/development/haskell-modules" {
            haskellLib = import "${baseNixpkgs}/pkgs/development/haskell-modules/lib.nix" {
              inherit (self) lib;
              pkgs = self;
            };
            buildHaskellPackages = haskellPackages; #self.buildPackages.haskell.packages.ghc843;
            ghc = ghcHEAD;
            compilerConfig = self1: super1: {
              # Packages included in GHC's global package database
              Cabal = null;
              array = null;
              base = null;
              binary = null;
              bytestring = null;
              containers = null;
              deepseq = null;
              directory = null;
              filepath = null;
              ghc-boot = null;
              ghc-boot-th = null;
              ghc-compact = null;
              ghc-prim = null;
              ghci = null;
              haskeline = null;
              hpc = null;
              integer-gmp = null;
              integer-simple = null;
              mtl = null;
              parsec = null;
              pretty = null;
              process = null;
              rts = null;
              stm = null;
              template-haskell = null;
              text = null;
              time = null;
              transformers = null;
              unix = null;

              doctest = haskellPackages.callPackage ./doctest.nix {};
              http-api-data = haskellPackages.callPackage ./http-api-data.nix {};
              tagged = self1.callHackage "tagged" "0.8.6" {};

              jailbreak-cabal = self.haskell.packages.ghc802.jailbreak-cabal;
              cabal2nix = self.haskell.packages.ghc843.cabal2nix;
            };
          };
      in baseHaskellPackages.extend overrides;

    headHackageScripts = self.stdenv.mkDerivation {
      name = "head-hackage-scripts";
      nativeBuildInputs = [ self.makeWrapper ];
      buildCommand = ''
        mkdir -p $out/bin
        makeWrapper ${scripts/patch-tool} $out/bin/patch-tool \
          --prefix PATH : ${super.haskellPackages.cabal-install}/bin \
          --prefix PATH : ${self.jq}/bin \
          --prefix PATH : ${self.curl}/bin

        makeWrapper ${scripts/head.hackage.sh} $out/bin/head.hackage.sh \
          --set CABAL ${super.haskellPackages.cabal-install}/bin/cabal
      '';
    };
  };
in import baseNixpkgs { overlays = [ overrides ]; }
