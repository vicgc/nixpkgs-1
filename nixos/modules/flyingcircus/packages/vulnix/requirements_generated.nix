# generated using pypi2nix tool (version: 1.5.0)
#
# COMMAND:
#   pypi2nix -V 3.4 -b buildout.cfg -E libxml2 libxslt -e pytest-runner -e setuptools-scm -v
#

{ pkgs, python, commonBuildInputs ? [], commonDoCheck ? false }:

self: {

  "BTrees" = python.mkDerivation {
    name = "BTrees-4.3.1";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/24/76/cd6f225f2180c22af5cdb6656f51aec5fca45e45bdc4fa75c0a32f161a61/BTrees-4.3.1.tar.gz";
      sha256 = "2565b7d35260dfc6b1e2934470fd0a2f9326c58c535a2b4cb396289d1c195a95";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [
      self."coverage"
      self."persistent"
      self."transaction"
      self."zope.interface"
    ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.zpt21;
      description = "Scalable persistent object containers";
    };
  };



  "PyYAML" = python.mkDerivation {
    name = "PyYAML-3.12";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/4a/85/db5a2df477072b2902b0eb892feb37d88ac635d36245a72a6a69b23b383a/PyYAML-3.12.tar.gz;
      sha256 = "1aqjl8dk9amd4zr99n8v2qxzgmr2hdvqfma4zh7a41rj6336c9sr";
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



  "ZConfig" = python.mkDerivation {
    name = "ZConfig-3.1.0";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/52/b3/a96d62711a26d8cfbe546519975dc9ed54d2eb50b3238d2e6de045764796/ZConfig-3.1.0.tar.gz";
      sha256 = "c21fa3a073a56925a8098036d46717392994a92cffea1b3cda3176b70c0a842e";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.zpt21;
      description = "Structured Configuration Library";
    };
  };



  "ZODB" = python.mkDerivation {
    name = "ZODB-5.4.0";
    src = pkgs.fetchurl {
      url = https://files.pythonhosted.org/packages/6a/8a/22c3b38ae95a61c861c1086609be9bdcddfe7ad4a912a5a74ee66e3bf638/ZODB-5.4.0.tar.gz;
      sha256 = "0b306042f4f0d558a477d65c34b0dd6e7604c6e583f55dfda52befa2fa13e076";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [
      self."BTrees"
      self."ZConfig"
      self."persistent"
      self."six"
      self."transaction"
      self."zc.lockfile"
      self."zodbpickle"
      self."zope.interface"
    ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.zpt21;
      description = "Zope Object Database: object database and persistence";
    };
  };



  "click" = python.mkDerivation {
    name = "click-6.7";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/95/d9/c3336b6b5711c3ab9d1d3a80f1a3e2afeb9d8c02a7166462f6cc96570897/click-6.7.tar.gz;
      sha256 = "02qkfpykbq35id8glfgwc38yc430427yd05z1wc5cnld8zgicmgi";
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



  "certifi" = python.mkDerivation {
    name = "certifi-2017.7.27.1";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/20/d0/3f7a84b0c5b89e94abbd073a5f00c7176089f526edb056686751d5064cbd/certifi-2017.7.27.1.tar.gz;
      sha256 = "1xg3m5zgap347w2bcfygi01r03lny2c24q247c8kwlk0zcp3slj0";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
  };



  "chardet" = python.mkDerivation {
    name = "chardet-3.0.4";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/fc/bb/a5768c230f9ddb03acc9ef3f0d4a3cf93462473795d18e9535498c8f929d/chardet-3.0.4.tar.gz;
      sha256 = "1bpalpia6r5x1kknbk11p1fzph56fmmnp405ds8icksd3knr5aw4";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
  };



  "colorama" = python.mkDerivation {
    name = "colorama-0.3.9";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/e6/76/257b53926889e2835355d74fec73d82662100135293e17d382e2b74d1669/colorama-0.3.9.tar.gz;
      sha256 = "1wd1szk0z3073ghx26ynw43gnc140ibln1safgsis6s6z3s25ss8";
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



  "coverage" = python.mkDerivation {
    name = "coverage-4.0.3";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/76/b4/3777a6bae434240b1fcbbda6cb30085bd897b3519acfffea498ee9f41038/coverage-4.0.3.tar.gz";
      sha256 = "85b1275b6d7a61ccc8024a4e9a4c9e896394776edce1a5d075ec116f91925462";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.asl20;
      description = "Code coverage measurement for Python";
    };
  };



  "idna" = python.mkDerivation {
    name = "idna-2.5";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/d8/82/28a51052215014efc07feac7330ed758702fc0581347098a81699b5281cb/idna-2.5.tar.gz;
      sha256 = "1ara12a7k2zc69msa0arrvw00gn61a6i6by01xb3lkkc0h4cxd9w";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
  };



  "lxml" = python.mkDerivation {
    name = "lxml-4.2.1";
    src = pkgs.fetchurl {
      url = https://files.pythonhosted.org/packages/e8/5d/98f56e274bdf17f2e0d9016d1788ca80d26d8987dcd5e1d9416d86ee0625/lxml-4.2.1.tar.gz;
      sha256 = "e2629cdbcad82b83922a3488937632a4983ecc0fed3e5cfbf430d069382eeb9b";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.bsdOriginal;
      description = "Powerful and Pythonic XML processing library combining libxml2/libxslt with the ElementTree API.";
    };
  };



  "mccabe" = python.mkDerivation {
    name = "mccabe-0.4.0";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/f6/e7/54461a958bb8b16f8db5f849d5d08b7d74153e064ac385fb68ff09f0bd27/mccabe-0.4.0.tar.gz";
      sha256 = "9a2b12ebd876e77c72e41ebf401cc2e7c5b566649d50105ca49822688642207b";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.mit;
      description = "McCabe checker, plugin for flake8";
    };
  };



  "pep8" = python.mkDerivation {
    name = "pep8-1.7.0";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/3e/b5/1f717b85fbf5d43d81e3c603a7a2f64c9f1dabc69a1e7745bd394cc06404/pep8-1.7.0.tar.gz";
      sha256 = "a113d5f5ad7a7abacef9df5ec3f2af23a20a28005921577b15dd584d099d5900";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.mit;
      description = "Python style guide checker";
    };
  };



  "persistent" = python.mkDerivation {
    name = "persistent-4.2.2";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/3d/71/3302512282b606ec4d054e09be24c065915518903b29380b6573bff79c24/persistent-4.2.2.tar.gz";
      sha256 = "52ececc6dbba5ef572d3435189318b4dff07675bafa9620e32f785e147c6563c";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [
      self."coverage"
      self."zope.interface"
    ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.zpt21;
      description = "Translucent persistent objects";
    };
  };



  "py" = python.mkDerivation {
    name = "py-1.4.34";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/68/35/58572278f1c097b403879c1e9369069633d1cbad5239b9057944bb764782/py-1.4.34.tar.gz;
      sha256 = "1qyd5z0hv8ymxy84v5vig3vps2fvhcf4bdlksb3r03h549fmhb8g";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.mit;
      description = "library with cross-python path, ini-parsing, io, code, log facilities";
    };
  };



  "pyflakes" = python.mkDerivation {
    name = "pyflakes-1.0.0";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/45/24/6bc038f3422bab08c24173c1990a56e9eb0c4582a9b202858a33f8aefeb8/pyflakes-1.0.0.tar.gz";
      sha256 = "f39e33a4c03beead8774f005bd3ecf0c3f2f264fa0201de965fce0aff1d34263";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.mit;
      description = "passive checker of Python programs";
    };
  };



  "requests" = python.mkDerivation {
    name = "requests-2.18.3";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/c3/38/d95ddb6cc8558930600be088e174a2152261a1e0708a18bf91b5b8c90b22/requests-2.18.3.tar.gz;
      sha256 = "065mh2cckg4gfl693dn7v3iqpqp68rd0yz6nkhnw2ra9xyxafs7v";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [
      self."urllib3"
      self."chardet"
      self."certifi"
      self."idna"
    ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.asl20;
      description = "Python HTTP for Humans.";
    };
  };



  "setuptools-scm" = python.mkDerivation {
    name = "setuptools-scm-1.15.6";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/03/6d/aafdd01edd227ee879b691455bf19895091872af7e48192bea1758c82032/setuptools_scm-1.15.6.tar.gz;
      sha256 = "0pzvfmx8s20yrgkgwfbxaspz2x1g38qv61jpm0ns91lrb22ldas9";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.mit;
      description = "the blessed package to manage your versions by scm tags";
    };
  };



  "six" = python.mkDerivation {
    name = "six-1.10.0";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/b3/b2/238e2590826bfdd113244a40d9d3eb26918bd798fc187e2360a8367068db/six-1.10.0.tar.gz";
      sha256 = "105f8d68616f8248e24bf0e9372ef04d3cc10104f1980f54d57b2ce73a5ad56a";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.mit;
      description = "Python 2 and 3 compatibility utilities";
    };
  };



  "toml" = python.mkDerivation {
    name = "toml-0.9.4";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/f5/f9/044110c267e6408013b85166a7cfcd352cf85275aa8ce700aa5c0eb407ba/toml-0.9.4.tar.gz";
      sha256 = "0bdbpbip67wdm6c7xwc6mmbmskyradj4cdxn1iibj4fcx1nbv1lf";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [
    ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.zpt21;
      description = "Python Library for Tom's Obvious, Minimal Language";
    };
  };



  "transaction" = python.mkDerivation {
    name = "transaction-2.0.3";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/8c/af/3ffafe85bcc93ecb09459f3f2bd8fbe142e9ab34048f9e2774543b470cbd/transaction-2.0.3.tar.gz";
      sha256 = "67bfb81309ba9717edbb2ca2e5717c325b78beec0bf19f44e5b4b9410f82df7f";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [
      self."coverage"
      self."zope.interface"
    ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.zpt21;
      description = "Transaction management for Python";
    };
  };



  "urllib3" = python.mkDerivation {
    name = "urllib3-1.22";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/ee/11/7c59620aceedcc1ef65e156cc5ce5a24ef87be4107c2b74458464e437a5d/urllib3-1.22.tar.gz;
      sha256 = "0kyvc9zdlxr5r96bng5rhm9a6sfqidrbvvkz64s76qs5267dli6c";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
  };



  "zc.lockfile" = python.mkDerivation {
    name = "zc.lockfile-1.2.1";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/bd/84/0299bbabbc9d3f84f718ba1039cc068030d3ad723c08f82a64337edf901e/zc.lockfile-1.2.1.tar.gz";
      sha256 = "11db91ada7f22fe8aae268d4bfdeae012c4fe655f66bbb315b00822ec00d043e";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [ ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.zpt21;
      description = "Basic inter-process locks";
    };
  };



  "zodbpickle" = python.mkDerivation {
    name = "zodbpickle-0.6.0";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/7a/fc/f6f437a5222b330735eaf8f1e67a6845bd1b600e9a9455e552d3c13c4902/zodbpickle-0.6.0.tar.gz";
      sha256 = "ea3248be966159e7791e3db0e35ea992b9235d52e7d39835438686741d196665";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [
      self."coverage"
    ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.zpt21;
      description = "Fork of Python 3 pickle module.";
    };
  };



  "zope.interface" = python.mkDerivation {
    name = "zope.interface-4.3.3";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/44/af/cea1e18bc0d3be0e0824762d3236f0e61088eeed75287e7b854d65ec9916/zope.interface-4.3.3.tar.gz";
      sha256 = "8780ef68ca8c3fe1abb30c058a59015129d6e04a6b02c2e56b9c7de6078dfa88";
    };
    doCheck = commonDoCheck;
    buildInputs = commonBuildInputs;
    propagatedBuildInputs = [
      self."coverage"
    ];
    meta = with pkgs.stdenv.lib; {
      homepage = "";
      license = licenses.zpt21;
      description = "Interfaces for Python";
    };
  };

}
