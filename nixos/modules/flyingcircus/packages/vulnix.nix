{ pkgs, ...  }:

let
  vulnix = pkgs.fetchFromGitHub {
    rev = "047185d9";
    owner = "flyingcircusio";
    repo = "vulnix";
    sha256 = "0bn104a3azjjjc7vkkh8dnd3hw394x28xgpa07c836mklrzwhyz4";
  };
in
import vulnix { inherit pkgs; }
