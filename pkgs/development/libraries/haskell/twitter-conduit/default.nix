# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, aeson, attoparsec, authenticateOauth, caseInsensitive
, conduit, conduitExtra, dataDefault, doctest, filepath, hlint
, hspec, httpClient, httpConduit, httpTypes, lens, monadControl
, monadLogger, network, resourcet, shakespeare, text, time
, transformers, transformersBase, twitterTypes
}:

cabal.mkDerivation (self: {
  pname = "twitter-conduit";
  version = "0.0.5.5";
  sha256 = "13wk863xjlg8g62yhbq4aar7z77n0awh500l6v41fam99lihzxab";
  isLibrary = true;
  isExecutable = true;
  buildDepends = [
    aeson attoparsec authenticateOauth conduit conduitExtra dataDefault
    httpClient httpConduit httpTypes lens monadLogger resourcet
    shakespeare text time transformers twitterTypes
  ];
  testDepends = [
    aeson attoparsec authenticateOauth caseInsensitive conduit
    conduitExtra dataDefault doctest filepath hlint hspec httpClient
    httpConduit httpTypes lens monadControl monadLogger network
    resourcet shakespeare text time transformers transformersBase
    twitterTypes
  ];
  meta = {
    homepage = "https://github.com/himura/twitter-conduit";
    description = "Twitter API package with conduit interface and Streaming API support";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
    maintainers = with self.stdenv.lib.maintainers; [ ocharles ];
  };
})
