{ mkDerivation, base, base-compat, code-page, deepseq, directory
, filepath, ghc, ghc-paths, hspec, HUnit, mockery, process
, QuickCheck, setenv, silently, stdenv, stringbuilder, syb
, transformers, with-location
}:
mkDerivation {
  pname = "doctest";
  version = "0.16.0";
  sha256 = "bb49a6781b6deda4eaa9cc3e3b515f245e4b23c4eb403316b873e86220636c42";
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    base base-compat code-page deepseq directory filepath ghc ghc-paths
    process syb transformers
  ];
  executableHaskellDepends = [
    base base-compat code-page deepseq directory filepath ghc ghc-paths
    process syb transformers
  ];
  testHaskellDepends = [
    base base-compat code-page deepseq directory filepath ghc ghc-paths
    hspec HUnit mockery process QuickCheck setenv silently
    stringbuilder syb transformers with-location
  ];
  homepage = "https://github.com/sol/doctest#readme";
  description = "Test interactive Haskell examples";
  license = stdenv.lib.licenses.mit;
}
