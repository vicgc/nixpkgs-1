# Collection of local Python libraries, similar to upstream python-packages.nix.
# Packages defined here will be part of pkgs.python27Packages,
# pkgs.python34Packages and so on. Restrict Python compatibility through meta
# attributes if necessary.
# Python _applications_ which should get built only against a specific Python
# version are better off in all-packages.nix.
{ pkgs, stdenv, python, self, buildPythonPackage }:

let
  lib = pkgs.lib;

in rec {
  click = buildPythonPackage {
    name = "click-6.6";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/7a/00/c14926d8232b36b08218067bcd5853caefb4737cda3f0a47437151344792/click-6.6.tar.gz;
      sha256 = "cc6a19da8ebff6e7074f731447ef7e112bd23adf3de5c597cf9989f2fd8defe9";
    };
    doCheck = false;
    meta = with pkgs.stdenv.lib; {
      homepage = http://click.pocoo.org/5/;
      license = licenses.bsdOriginal;
      description = "A simple wrapper around optparse for powerful command line utilities.";
    };
  };

  fcutil = buildPythonPackage rec {
    name = "fc-util-${version}";
    version = "1.0";
    src = ./fcutil;
    buildInputs = [
      self.pytest-runner
    ];
    doCheck = false;
  };

  # backported from 17.09
  fetchPypi = lib.makeOverridable( {format ? "setuptools", ... } @attrs:
    let
      fetchWheel = {pname, version, sha256, python ? "py2.py3", abi ? "none", platform ? "any"}:
      # Fetch a wheel. By default we fetch an universal wheel.
      # See https://www.python.org/dev/peps/pep-0427/#file-name-convention for details regarding the optional arguments.
        let
          url = "https://files.pythonhosted.org/packages/${python}/${builtins.substring 0 1 pname}/${pname}/${pname}-${version}-${python}-${abi}-${platform}.whl";
        in pkgs.fetchurl {inherit url sha256;};
      fetchSource = {pname, version, sha256, extension ? "tar.gz"}:
      # Fetch a source tarball.
        let
          url = "mirror://pypi/${builtins.substring 0 1 pname}/${pname}/${pname}-${version}.${extension}";
        in pkgs.fetchurl {inherit url sha256;};
      fetcher = (if format == "wheel" then fetchWheel
        else if format == "setuptools" then fetchSource
        else throw "Unsupported kind ${format}");
    in fetcher (builtins.removeAttrs attrs ["format"]) );

  freezegun = buildPythonPackage rec {
    name = "freezegun-${version}";
    version = "0.3.6";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/source/f/freezegun/freezegun-0.3.6.tar.gz;
      md5 = "c321cf7392343f91e524eec0b601e8ec";
    };
    propagatedBuildInputs = with self; [ dateutil ];
    dontStrip = true;
    doCheck = false;
  };

  nagiosplugin = buildPythonPackage rec {
    name = "nagiosplugin-${version}";
    version = "1.2.4";
    src = pkgs.fetchurl {
      url = "https://pypi.python.org/packages/f0/82/4c54ab5ee763c452350d65ce9203fb33335ae5f4efbe266aaa201c9f30ad/nagiosplugin-1.2.4.tar.gz";
      md5 = "f22ee91fc89d0c442803bdf27fab8c99";
    };
    doCheck = false;  # "cannot determine number of users (who failed)"
    dontStrip = true;
  };

  pytestcatchlog = buildPythonPackage rec {
    name = "pytest-catchlog-${version}";
    version = "1.2.2";
    src = pkgs.fetchurl {
      url = https://pypi.python.org/packages/source/p/pytest-catchlog/pytest-catchlog-1.2.2.zip;
      md5 = "09d890c54c7456c818102b7ff8c182c8";
    };
    propagatedBuildInputs = with self; [ pytest ];
    dontStrip = true;
  };

  pytest-runner = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "pytest-runner";
    version = "3.0";
    src = self.fetchPypi {
      inherit pname version;
      sha256 = "00v7pi09q60yx0l1kzyklnmr5bp597mir85a9gsi7bdfyly3lz0g";
    };
    propagatedBuildInputs = with self; [
      pytest
      setuptools_scm
    ];
    dontStrip = true;
  };

  setuptools_scm = buildPythonPackage rec {
    name = "${pname}-${version}";
    pname = "setuptools_scm";
    version = "1.15.6";
    src = self.fetchPypi {
      inherit pname version;
      sha256 = "0pzvfmx8s20yrgkgwfbxaspz2x1g38qv61jpm0ns91lrb22ldas9";
    };
    buildInputs = with self; [ pip ];
    dontStrip = true;
    preBuild = ''
      ${python.interpreter} setup.py egg_info
    '';
  };

}
