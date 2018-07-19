{ mkDerivation, attoparsec, attoparsec-iso8601, base, bytestring
, Cabal, cabal-doctest, containers, directory, doctest, filepath
, hashable, hspec, hspec-discover, http-types, HUnit, QuickCheck
, quickcheck-instances, stdenv, text, time, time-locale-compat
, unordered-containers, uri-bytestring, uuid-types
}:
mkDerivation {
  pname = "http-api-data";
  version = "0.3.8.1";
  sha256 = "6eeaba4b29a00407cb20b865825b17b8d884c26b09c5bbe7b6e673b4522106b3";
  setupHaskellDepends = [ base Cabal cabal-doctest ];
  libraryHaskellDepends = [
    attoparsec attoparsec-iso8601 base bytestring containers hashable
    http-types text time time-locale-compat unordered-containers
    uri-bytestring uuid-types
  ];
  testHaskellDepends = [
    base bytestring directory doctest filepath hspec HUnit QuickCheck
    quickcheck-instances text time unordered-containers uuid-types
  ];
  testToolDepends = [ hspec-discover ];
  homepage = "http://github.com/fizruk/http-api-data";
  description = "Converting to/from HTTP API data like URL pieces, headers and query parameters";
  license = stdenv.lib.licenses.bsd3;
}
