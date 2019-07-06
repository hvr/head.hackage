{ stdenv
  , haskell
  , patches  # A directory containing patch files used to build packages
             # it can either be a local directory or fetched from the web
}:
let
  hpkgs = haskell.packages.ghc864.extend (self: super:
            { aeson = haskell.lib.addBuildDepends super.aeson [self.contravariant]; });
  ghc   = hpkgs.ghcWithPackages (ps: with ps;
            [ hopenssl distribution-nixpkgs ]);
in

stdenv.mkDerivation {

  name = "hs-generate-overrides-0.1";

  src = ./generate-nix-overrides.hs;

  preUnpack = ''mkdir hs-generate-overrides'';
  buildInputs = [ ghc ];

  unpackCmd = ''
    cp $curSrc ./hs-generate-overrides
    cp -r ${patches} ./hs-generate-overrides/patches
    sourceRoot=hs-generate-overrides;
  '';

  buildPhase = ''
    ghc $src -o generate
    ./generate $script/patches patches > patches.nix
  '';

  outputs = ["out" "script"];

  installPhase = ''
    cp patches.nix $out
    mkdir -p $script/patches
    cp -r patches $script/patches
  '';

}


