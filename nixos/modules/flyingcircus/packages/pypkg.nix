# Collection of local Python packages, similar in spirit to python-packages.nix.
{ pkgs, python34Packages, ... }:

with python34Packages;

rec {

  setuptools_scm = buildPythonPackage rec {
    name = "setuptools_scm-${version}";
    version = "1.11.1";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/84/aa/c693b5d41da513fed3f0ee27f1bf02a303caa75bbdfa5c8cc233a1d778c4/setuptools_scm-1.11.1.tar.gz";
      md5 = "4d19b2bc9580016d991f665ac20e2e8f";
    };
    buildInputs = [ pip ];
    dontStrip = true;
    preBuild = ''
      ${python.interpreter} setup.py egg_info
    '';
    meta = with pkgs.lib; {
      homepage = https://bitbucket.org/pypa/setuptools_scm/;
      description = "Handles managing your python package versions in scm metadata";
      license = licenses.mit;
      maintainers = with maintainers; [ jgeerds ];
    };
  };

  pytestcatchlog = buildPythonPackage rec {
    name = "pytest-catchlog-${version}";
    version = "1.2.2";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/source/p/pytest-catchlog/pytest-catchlog-1.2.2.zip;
      md5 = "09d890c54c7456c818102b7ff8c182c8";
    };
    propagatedBuildInputs = [ pytest ];
    dontStrip = true;
  };

  freezegun = buildPythonPackage rec {
    name = "freezegun-${version}";
    version = "0.3.6";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/source/f/freezegun/freezegun-0.3.6.tar.gz;
      md5 = "c321cf7392343f91e524eec0b601e8ec";
    };
    propagatedBuildInputs = [ dateutil ];
    dontStrip = true;
    doCheck = false;
  };

}
