# Specify the precise commit of GHC that we are going to use by default
nixpkgs:
let spec =
  {
    version = "8.6.1.20180716";
    src =
      nixpkgs.fetchgit {
        url = "git://git.haskell.org/ghc.git";
        rev = "ghc-8.6.1-alpha2";
        sha256 = "03y824yfy1xh2cznq5q75sql8pb0lxyw9ry82jgms9jampky98x6";
      };
  };
in

(nixpkgs.haskell.compiler.ghcHEAD.override
    { version = spec.version
    ; bootPkgs = nixpkgs.haskell.packages.ghc822; }).overrideAttrs(oldAttrs:
    { src = spec.src; })

