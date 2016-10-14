# generated using pypi2nix tool (version: 1.5.0)
#
# COMMAND:
#   pypi2nix -V 3.4 -e vulnix==1.1.5
#

{ pkgs, python, commonBuildInputs ? [], commonDoCheck ? false }:

self: {

  "PyYAML" = python.mkDerivation {
    name = "PyYAML-3.12";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/4a/85/db5a2df477072b2902b0eb892feb37d88ac635d36245a72a6a69b23b383a/PyYAML-3.12.tar.gz";
      sha256 = "592766c6303207a20efc445587778322d7f73b161bd994f227adaa341ba212ab";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.mit;
      description = "YAML parser and emitter for Python";
    };
  };



  "click" = python.mkDerivation {
    name = "click-6.6";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/7a/00/c14926d8232b36b08218067bcd5853caefb4737cda3f0a47437151344792/click-6.6.tar.gz";
      sha256 = "cc6a19da8ebff6e7074f731447ef7e112bd23adf3de5c597cf9989f2fd8defe9";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.bsdOriginal;
      description = "A simple wrapper around optparse for powerful command line utilities.";
    };
  };



  "colorama" = python.mkDerivation {
    name = "colorama-0.3.7";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/f0/d0/21c6449df0ca9da74859edc40208b3a57df9aca7323118c913e58d442030/colorama-0.3.7.tar.gz";
      sha256 = "e043c8d32527607223652021ff648fbb394d5e19cba9f1a698670b338c9d782b";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.bsdOriginal;
      description = "Cross-platform colored terminal text.";
    };
  };



  "requests" = python.mkDerivation {
    name = "requests-2.11.1";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/2e/ad/e627446492cc374c284e82381215dcd9a0a87c4f6e90e9789afefe6da0ad/requests-2.11.1.tar.gz";
      sha256 = "5acf980358283faba0b897c73959cecf8b841205bb4b2ad3ef545f46eae1a133";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.asl20;
      description = "Python HTTP for Humans.";
    };
  };



  "vulnix" = python.mkDerivation {
    name = "vulnix-1.1.5";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/de/1e/66ce22166bfcf60853511ba2d0b663ece96dd5df34a5077d176391db927d/vulnix-1.1.5.tar.gz";
      sha256 = "9b729d4ba29aaac2c2735b38b97bb96d42762a8d81ac66e77aa9bda39eca3241";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [
      self."PyYAML"
      self."click"
      self."colorama"
      self."requests"
    ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.bsdOriginal;
      description = "Scans a Nix store for derivations that are affected by vulnerabilities.";
    };
  };

}