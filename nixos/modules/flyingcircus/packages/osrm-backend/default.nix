{stdenv, fetchFromGitHub, cmake, luabind, libosmpbf, stxxl, tbb, boost, expat, protobuf, bzip2, zlib, substituteAll}:

stdenv.mkDerivation rec {
  name = "osrm-backend-5.11.0";

  src = fetchFromGitHub {
    rev = "v5.11.0";
    owner  = "Project-OSRM";
    repo   = "osrm-backend";
    sha256 = "1d5c3p7z4m3dg7pwgq3lk6hqdz3l0lc077nf533m3ds3a5gys2vq";
  };

  buildInputs = [ cmake luabind libosmpbf stxxl tbb boost expat protobuf bzip2 zlib ];

  postInstall = "mkdir -p $out/share/osrm-backend && cp -r ../profiles $out/share/osrm-backend/profiles";

  meta = {
    homepage = https://github.com/Project-OSRM/osrm-backend/wiki;
    description = "Open Source Routing Machine computes shortest paths in a graph. It was designed to run well with map data from the Openstreetmap Project";
    license = stdenv.lib.licenses.bsd2;
  };
}
