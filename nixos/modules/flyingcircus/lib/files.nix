{ lib, fclib, ... }:
with lib;
rec {

  # Get all regular files with their name relative to path
  filesRel = path:
    optionals
      (pathExists path)
      (attrNames
        (filterAttrs
          (filename: type: (type == "regular"))
          (readDir path)));

  # Get all regular files with their absolute name
  files = path:
    (map
      (filename: path + "/" + filename)
      (filesRel path));

}
