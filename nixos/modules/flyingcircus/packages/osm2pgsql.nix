{ pkgs ? import <nixpkgs> { }
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib
, fetchurl ? pkgs.fetchurl
}:

stdenv.mkDerivation rec {
  name = "osm2pgsql-${version}";
  version = "0.92.1";
  src = fetchurl {
    url = "https://github.com/openstreetmap/osm2pgsql/archive/${version}.tar.gz";
    sha256 = "142k08q6mv63zvbcscfc9m1xnnlpfflb3jkdiyvx93m3m92a64h9";
  };

  buildInputs = [
    pkgs.boost
    pkgs.bzip2
    pkgs.cmake
    pkgs.expat
    pkgs.geos
    pkgs.lua
    pkgs.postgresql
    pkgs.proj
    pkgs.zlib
  ];

  enableParallelBuilding = true;

  meta = {
    homepage = https://github.com/openstreetmap/osm2pgsql;
    description = "osm2pgsql is a tool for loading OpenStreetMap data into a PostgreSQL / PostGIS database suitable for applications like rendering into a map, geocoding with Nominatim, or general analysis.";
  };
}
