{ ghcTree }:

let
  jailbreakOverrides = self: super: {
    mkDerivation = drv: super.mkDerivation (drv // { jailbreak = true; doHaddock = false; });
  };

  overrides = self: super: rec {
    ghcHEAD =
      let
        base = self.callPackage "${baseNixpkgs}/pkgs/development/compilers/ghc/head.nix" rec {
          bootPkgs = self.haskell.packages.ghc843;
          inherit (bootPkgs) alex happy hscolour;
          buildLlvmPackages = self.buildPackages.llvmPackages_6;
          llvmPackages = self.llvmPackages_6;
          version = "8.6.0";
        };
      in base.overrideAttrs (oldAttrs: {
        #preConfigure = oldAttrs.preConfigure + "\nrm mk/build.mk\n";
        src = with self.lib; cleanSourceWith {
          src = ghcTree;
          filter = name: type: cleanSourceFilter name type
            && ! hasSuffix "are-validating.mk" name
            && ! hasSuffix "_build" name;
            # && ! hasSuffix "bindisttest/" name;
        };
      });

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

              jailbreak-cabal = self.haskell.packages.ghc802.jailbreak-cabal;
            };
          };
      in baseHaskellPackages.extend overrides;
  };

  baseNixpkgs = (import <nixpkgs> {}).fetchFromGitHub {
    owner = "nixos";
    repo = "nixpkgs";
    rev = "ff0641ceea9e652e0f21f6805a2b618cde6597a2";
    sha256 = null;
  };
in import baseNixpkgs { overlays = [ overrides ]; }
