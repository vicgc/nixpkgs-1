{ pkgs ? import <nixpkgs> { }
, stdenv ? pkgs.stdenv
, lib ? pkgs.lib
, fetchurl ? pkgs.fetchurl
}:

stdenv.mkDerivation rec {
  name = "osm2pgsql-${version}";
  version = "0.90.0";
  src = fetchurl {
    url = "https://github.com/openstreetmap/osm2pgsql/archive/${version}.tar.gz";
    sha256 = "1n2gxy4awzayildq3yn1q78gyy4phkrjf4rmxhpqpkdj9b2m7gyf";
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
