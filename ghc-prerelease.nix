# Specify the precise commit of GHC that we are going to use by default
nixpkgs:
let spec =
  {
    version = "8.8.1.20190613";
    src =
      nixpkgs.fetchgit {
        url = "https://gitlab.haskell.org/ghc/ghc.git";
        rev = "ghc-8.8.1-alpha2";
        sha256 = "0bhki6icpadspdlq2yl6sm7dg52gsmj7sgvjbh6nlgnxayq4ib2k";
      };
  };
in

(nixpkgs.haskell.compiler.ghcHEAD.override
    { version = spec.version
    ; bootPkgs = nixpkgs.haskell.packages.ghc864; }).overrideAttrs(oldAttrs:
    { src = spec.src; patches = []; })

