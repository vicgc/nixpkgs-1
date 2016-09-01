{ pkgs, ...  }:

let
  vulnix = pkgs.fetchFromGitHub {
    rev = "f15f8acd0b5410f6dc55dea60179918108def9a0";
    owner = "flyingcircusio";
    repo = "vulnix";
    sha256 = "1z6x8i93n8zg2wsws0ik7h4qbl5mr31dh0cxisnqv6rq79s6j1vp";
  };
in
import vulnix { inherit pkgs; }
