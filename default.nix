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
  rev = "73392e79aa62e406683d6a732eb4f4101f4732be";
  baseNixpkgs =
    builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${rev}.tar.gz";
    sha256 = "049fq37sxdn5iis7ni407j2jsfrxbb41pgv5zawi02qj47f74az9";
  };
in

# ghc: path to a GHC source tree
{ ghc ? import ./ghc-prerelease.nix }:

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

              aeson = haskellPackages.callHackage "aeson" "1.4.4.0" {};
              primitive = haskellPackages.callHackage "primitive" "0.7.0.0" {};
              haskell-src-exts = self1.haskell-src-exts_1_21_0;
              th-abstraction = haskellPackages.callHackage "th-abstraction" "0.3.1.0" {};
              time-compat = haskellPackages.callHackage "time-compat" "1.9.2.2" {};
              socks = haskellPackages.callHackage "socks" "0.6.0" {};
              connection = haskellPackages.callHackage "connection" "0.3.0" {};
              shelly = haskellPackages.callHackage "shelly" "1.8.1" {};

              jailbreak-cabal = self.haskell.packages.ghc864.jailbreak-cabal;
              cabal2nix = self.haskell.packages.ghc864.cabal2nix;
            };
          };
      in baseHaskellPackages.override (old: {
        overrides = self.lib.composeExtensions (old.overrides or (_: _: {})) overrides;
      });


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
