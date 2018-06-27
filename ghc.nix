# Specify the precise commit of GHC that we are going to use by default
nixpkgs:
let spec =
  {
    version = "8.6.20180622";
    src =
      nixpkgs.fetchgit {
        url = "git://git.haskell.org/ghc.git";
        rev = "c35ad6e0b3c62976e6251f1e9c47fe83ff15f4ce";
        sha256 = "1n4pa7igyx3dck8mx1kgzb52hs44x7c4bxd2w80q68z0qwizfkny";
      };
  };
in

(nixpkgs.haskell.compiler.ghcHEAD.override
    { version = spec.version
    ; bootPkgs = nixpkgs.haskell.packages.ghc822; }).overrideAttrs(oldAttrs:
    { src = spec.src; })

