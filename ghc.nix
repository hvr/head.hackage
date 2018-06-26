# Specify the precise commit of GHC that we are going to use by default
nixpkgs:
let spec =
  {
    version = "8.6.1.20180627";
    src =
      nixpkgs.fetchgit {
        url = "git://git.haskell.org/ghc.git";
        rev = "ghc-8.6.1-alpha1";
        sha256 = "0wjd0nm9q86hmw3vjii3543xpvgh8rbp46amg2mv09yci9pa23jm";
      };
  };
in

(nixpkgs.haskell.compiler.ghcHEAD.override
    { version = spec.version
    ; bootPkgs = nixpkgs.haskell.packages.ghc822; }).overrideAttrs(oldAttrs:
    { src = spec.src; })

