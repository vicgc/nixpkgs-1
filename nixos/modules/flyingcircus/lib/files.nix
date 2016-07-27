{ lib, fclib, ... }:
with lib;
rec {

  # Get all regular files with their name relative to path
  filesRel = path:
    optionals
      (builtins.pathExists path)
      (attrNames
        (filterAttrs
          (filename: type: (type == "regular"))
          (builtins.readDir path)));

  # Get all regular files with their absolute name
  files = path:
    (map
      (filename: path + "/" + filename)
      (filesRel path));

}
